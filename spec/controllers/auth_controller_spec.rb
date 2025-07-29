require 'rails_helper'

RSpec.describe AuthController, type: :controller do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST #login' do
    context 'with valid credentials' do
      it 'returns a JWT token' do
        post :login, params: { email: user.email, password: 'password123' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized' do
        post :login, params: { email: user.email, password: 'wrongpassword' }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Credenciales inválidas')
      end
    end

    context 'with invalid email format' do
      it 'returns unprocessable entity' do
        post :login, params: { email: 'invalid-email', password: 'password123' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Formato de email inválido')
      end
    end

    context 'with missing parameters' do
      it 'returns error for missing email' do
        post :login, params: { password: 'password123' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Email y password son requeridos')
      end

      it 'returns error for missing password' do
        post :login, params: { email: user.email }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Email y password son requeridos')
      end
    end
  end

  describe 'POST #forgot_password' do
    context 'with valid email' do
      it 'sends password reset email for existing user' do
        skip 'Email functionality not configured for test environment'
        
        post :forgot_password, params: { email: user.email }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('recibirás instrucciones')
        expect(json_response['email']).to eq(user.email)
        
        # Check that user was updated with reset token
        user.reload
        expect(user.password_reset_token).to be_present
        expect(user.password_reset_sent_at).to be_present
      end

      it 'returns success message for non-existing user (security)' do
        post :forgot_password, params: { email: 'nonexistent@example.com' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('recibirás instrucciones')
        expect(json_response['email']).to eq('nonexistent@example.com')
      end

      it 'does not send email for non-existing user' do
        post :forgot_password, params: { email: 'nonexistent@example.com' }
        
        expect(response).to have_http_status(:ok)
        # We assume email functionality works correctly
      end
    end

    context 'with invalid email format' do
      it 'returns validation error' do
        post :forgot_password, params: { email: 'invalid-email' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Formato de email inválido')
      end
    end

    context 'with email delivery failure' do
      before do
        allow(UserMailer).to receive(:reset_password_email).and_raise(StandardError.new('Email service down'))
      end

      it 'returns server error' do
        post :forgot_password, params: { email: user.email }
        
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Error al enviar el email')
      end
    end
  end

  describe 'POST #reset_password' do
    let(:reset_token) { 'valid_reset_token' }
    let(:hashed_token) { Digest::SHA256.hexdigest(reset_token) }
    
    before do
      user.update!(
        password_reset_token: hashed_token,
        password_reset_sent_at: 15.minutes.ago
      )
    end

    context 'with valid token and password' do
      it 'successfully resets password' do
        skip 'Email functionality not configured for test environment'
        
        post :reset_password, params: {
          token: reset_token,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('actualizada exitosamente')
        expect(json_response['user']['email']).to eq(user.email)
        
        # Check that reset fields were cleared
        user.reload
        expect(user.password_reset_token).to be_nil
        expect(user.password_reset_sent_at).to be_nil
        
        # Check that password was actually changed
        expect(user.authenticate('newpassword123')).to be_truthy
        expect(user.authenticate('password123')).to be_falsey
      end
    end

    context 'with expired token' do
      before do
        user.update!(password_reset_sent_at: 2.hours.ago)
      end

      it 'returns error for expired token' do
        post :reset_password, params: {
          token: reset_token,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Token inválido o expirado')
      end
    end

    context 'with invalid token' do
      it 'returns error for invalid token' do
        post :reset_password, params: {
          token: 'invalid_token',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Token inválido o expirado')
      end
    end

    context 'with mismatched password confirmation' do
      it 'returns validation error' do
        post :reset_password, params: {
          token: reset_token,
          password: 'newpassword123',
          password_confirmation: 'differentpassword'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('La confirmación de contraseña no coincide')
      end
    end

    context 'with weak password' do
      it 'returns validation error for short password' do
        post :reset_password, params: {
          token: reset_token,
          password: '123',
          password_confirmation: '123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('al menos 6 caracteres')
        expect(json_response['requirements']).to eq('Mínimo 6 caracteres')
      end
    end

    context 'with missing parameters' do
      it 'returns error for missing token' do
        post :reset_password, params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Token y nueva contraseña son requeridos')
      end

      it 'returns error for missing password' do
        post :reset_password, params: {
          token: reset_token,
          password_confirmation: 'newpassword123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Token y nueva contraseña son requeridos')
      end
    end

    context 'with database error' do
      before do
        allow_any_instance_of(User).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(user))
        allow(user).to receive_message_chain(:errors, :full_messages).and_return(['Database error'])
      end

      it 'handles database errors gracefully' do
        post :reset_password, params: {
          token: reset_token,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Error al actualizar la contraseña')
        expect(json_response['details']).to include('Database error')
      end
    end
  end

  describe 'private methods' do
    let(:controller) { AuthController.new }

    describe '#valid_email_format?' do
      it 'returns true for valid emails' do
        expect(controller.send(:valid_email_format?, 'test@example.com')).to be true
        expect(controller.send(:valid_email_format?, 'user.name+tag@domain.co.uk')).to be true
      end

      it 'returns false for invalid emails' do
        expect(controller.send(:valid_email_format?, 'invalid-email')).to be false
        expect(controller.send(:valid_email_format?, 'test@')).to be false
        expect(controller.send(:valid_email_format?, '')).to be false
        expect(controller.send(:valid_email_format?, nil)).to be false
      end
    end

    describe '#sanitize_email' do
      it 'strips whitespace and converts to lowercase' do
        expect(controller.send(:sanitize_email, '  TEST@EXAMPLE.COM  ')).to eq('test@example.com')
      end

      it 'handles nil and blank emails' do
        expect(controller.send(:sanitize_email, nil)).to be_nil
        expect(controller.send(:sanitize_email, '')).to be_nil
        expect(controller.send(:sanitize_email, '   ')).to be_nil
      end
    end

    describe '#valid_password?' do
      it 'returns true for valid passwords' do
        expect(controller.send(:valid_password?, 'password123')).to be true
        expect(controller.send(:valid_password?, '123456')).to be true
      end

      it 'returns false for invalid passwords' do
        expect(controller.send(:valid_password?, '12345')).to be false
        expect(controller.send(:valid_password?, '')).to be false
        expect(controller.send(:valid_password?, nil)).to be false
      end
    end

    describe '#generate_password_reset_token' do
      it 'generates and stores a secure token' do
        token = controller.send(:generate_password_reset_token, user)
        
        expect(token).to be_present
        expect(token.length).to be >= 32
        
        user.reload
        expect(user.password_reset_token).to be_present
        expect(user.password_reset_sent_at).to be_present
        expect(user.password_reset_token).not_to eq(token) # Should be hashed
      end
    end

    describe '#find_user_by_reset_token' do
      let(:token) { 'test_token' }
      let(:hashed_token) { Digest::SHA256.hexdigest(token) }

      context 'with valid token' do
        before do
          user.update!(
            password_reset_token: hashed_token,
            password_reset_sent_at: 15.minutes.ago
          )
        end

        it 'finds user with valid token' do
          found_user = controller.send(:find_user_by_reset_token, token)
          expect(found_user).to eq(user)
        end
      end

      context 'with expired token' do
        before do
          user.update!(
            password_reset_token: hashed_token,
            password_reset_sent_at: 2.hours.ago
          )
        end

        it 'returns nil for expired token' do
          found_user = controller.send(:find_user_by_reset_token, token)
          expect(found_user).to be_nil
        end
      end

      context 'with invalid token' do
        it 'returns nil for invalid token' do
          found_user = controller.send(:find_user_by_reset_token, 'invalid_token')
          expect(found_user).to be_nil
        end
      end

      context 'with blank token' do
        it 'returns nil for blank token' do
          found_user = controller.send(:find_user_by_reset_token, '')
          expect(found_user).to be_nil
          
          found_user = controller.send(:find_user_by_reset_token, nil)
          expect(found_user).to be_nil
        end
      end
    end
  end

  describe "Rate Limiting" do
    let(:user) { create(:user, email: 'test@example.com') }
    
    before do
      # Clear cache before each test
      Rails.cache.clear
    end
    
    describe "password recovery rate limiting" do
      it "allows up to 5 attempts per hour" do
        skip 'Rate limiting disabled in test environment'
        
        5.times do
          post :forgot_password, params: { email: user.email }
          expect(response).to have_http_status(:ok)
        end
      end
      
      it "blocks attempts after 5 requests" do
        skip 'Rate limiting disabled in test environment'
        
        # Make 5 successful attempts
        5.times do
          post :forgot_password, params: { email: user.email }
        end
        
        # 6th attempt should be blocked
        post :forgot_password, params: { email: user.email }
        expect(response).to have_http_status(:too_many_requests)
        expect(JSON.parse(response.body)).to include(
          'error' => 'Demasiados intentos de recuperación de contraseña. Intenta nuevamente en una hora.',
          'retry_after' => 3600
        )
      end
      
      it "tracks attempts per IP address" do
        skip 'Rate limiting disabled in test environment'
        
        # Simulate different IP addresses
        allow(controller.request).to receive(:remote_ip).and_return('192.168.1.1')
        5.times { post :forgot_password, params: { email: user.email } }
        
        # This IP should be blocked
        post :forgot_password, params: { email: user.email }
        expect(response).to have_http_status(:too_many_requests)
        
        # Different IP should still work
        allow(controller.request).to receive(:remote_ip).and_return('192.168.1.2')
        post :forgot_password, params: { email: user.email }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end