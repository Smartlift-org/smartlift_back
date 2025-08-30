class ExpoNotificationService
  include HTTParty
  base_uri 'https://exp.host/--/api/v2/push'
  
  def initialize
    @headers = {
      'Accept' => 'application/json',
      'Accept-Encoding' => 'gzip, deflate',
      'Content-Type' => 'application/json'
    }
    
    # Agregar token de autorización si está disponible
    if ENV['EXPO_ACCESS_TOKEN'].present?
      @headers['Authorization'] = "Bearer #{ENV['EXPO_ACCESS_TOKEN']}"
    end
  end
  
  def send_notification(token:, title:, body:, data: {})
    return false unless valid_expo_token?(token)
    
    payload = {
      to: token,
      title: title,
      body: body,
      data: data,
      sound: 'default',
      badge: 1,
      priority: 'high',
      channelId: 'chat'
    }
    
    begin
      response = self.class.post('/send', {
        headers: @headers,
        body: payload.to_json,
        timeout: 10
      })
      
      if response.success?
        Rails.logger.info "Expo notification sent successfully: #{response.code}"
        handle_response(response, token)
        true
      else
        Rails.logger.error "Expo notification failed: #{response.code} - #{response.body}"
        false
      end
    rescue Net::TimeoutError => e
      Rails.logger.error "Expo notification timeout: #{e.message}"
      false
    rescue => e
      Rails.logger.error "Expo notification error: #{e.message}"
      false
    end
  end
  
  def send_batch_notifications(notifications)
    return false if notifications.empty?
    
    valid_notifications = notifications.select { |n| valid_expo_token?(n[:to]) }
    return false if valid_notifications.empty?
    
    begin
      response = self.class.post('/send', {
        headers: @headers,
        body: valid_notifications.to_json,
        timeout: 15
      })
      
      if response.success?
        Rails.logger.info "Batch expo notifications sent: #{valid_notifications.size} notifications"
        true
      else
        Rails.logger.error "Batch expo notifications failed: #{response.code} - #{response.body}"
        false
      end
    rescue => e
      Rails.logger.error "Batch expo notifications error: #{e.message}"
      false
    end
  end
  
  private
  
  def valid_expo_token?(token)
    return false unless token.is_a?(String)
    return false if token.blank?
    
    # Validar formato básico del token de Expo
    token.match?(/^ExponentPushToken\[.+\]$/) || token.match?(/^ExpoPushToken\[.+\]$/)
  end
  
  def handle_response(response, token)
    data = response.parsed_response
    return unless data.is_a?(Hash)
    
    if data['data']&.is_a?(Array)
      data['data'].each_with_index do |result, index|
        handle_individual_result(result, token)
      end
    elsif data['status'] == 'error'
      handle_error_response(data, token)
    end
  end
  
  def handle_individual_result(result, token)
    return unless result.is_a?(Hash)
    
    case result['status']
    when 'error'
      error_type = result.dig('details', 'error')
      Rails.logger.error "Expo push error for token #{token[0..20]}...: #{error_type}"
      
      # Si el token es inválido, podríamos marcarlo para limpieza
      if ['DeviceNotRegistered', 'InvalidCredentials'].include?(error_type)
        Rails.logger.warn "Token #{token[0..20]}... should be cleaned up"
      end
    when 'ok'
      Rails.logger.debug "Expo push successful for token #{token[0..20]}..."
    end
  end
  
  def handle_error_response(data, token)
    error_message = data['message'] || 'Unknown error'
    Rails.logger.error "Expo push error for token #{token[0..20]}...: #{error_message}"
  end
end
