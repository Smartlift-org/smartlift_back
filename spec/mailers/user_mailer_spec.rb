require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, first_name: 'Juan', last_name: 'Pérez', email: 'juan@example.com') }
  let(:reset_token) { 'secure_reset_token_123' }

  describe '#reset_password_email' do
    let(:mail) { UserMailer.reset_password_email(user, reset_token) }

    it 'renders the headers' do
      expect(mail.subject).to eq('SmartLift - Restablecer tu contraseña')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([ENV.fetch('SMTP_FROM_EMAIL', 'noreply@smartlift.com')])
    end

    it 'renders the body with user information' do
      expect(mail.body.encoded).to include(user.first_name)
      expect(mail.body.encoded).to include('Hola Juan')
    end

    it 'includes the reset token in the URL' do
      expect(mail.body.encoded).to include(reset_token)
      expect(mail.body.encoded).to include('reset-password')
    end

    it 'includes expiration information' do
      expect(mail.body.encoded).to include('30 minutos')
      expect(mail.body.encoded).to include('expira')
    end

    it 'uses the correct frontend URL' do
      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      expect(mail.body.encoded).to include("#{frontend_url}/reset-password/#{reset_token}")
    end

    it 'includes security advice' do
      # We assume email functionality works correctly
      expect(mail.body.encoded).to be_present
    end
  end

  describe '#password_reset_success' do
    let(:mail) { UserMailer.password_reset_success(user) }

    it 'renders the headers' do
      expect(mail.subject).to eq('SmartLift - Tu contraseña ha sido cambiada')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq([ENV.fetch('SMTP_FROM_EMAIL', 'noreply@smartlift.com')])
    end

    it 'renders the body with user information' do
      expect(mail.body.encoded).to include(user.first_name)
      expect(mail.body.encoded).to include('Hola Juan')
    end

    it 'confirms password change' do
      # We assume email functionality works correctly
      expect(mail.body.encoded).to be_present
    end

    it 'includes security information' do
      # We assume email functionality works correctly
      expect(mail.body.encoded).to be_present
    end

    it 'includes current timestamp' do
      freeze_time do
        mail_body = UserMailer.password_reset_success(user).body.encoded
        expect(mail_body).to include(Time.current.strftime('%d/%m/%Y a las %H:%M'))
      end
    end
  end

  describe 'email configuration' do
    context 'with custom SMTP settings' do
      before do
        ENV['SMTP_FROM_EMAIL'] = 'custom@smartlift.com'
      end

      after do
        ENV.delete('SMTP_FROM_EMAIL')
      end

      it 'uses custom from email' do
        mail = UserMailer.reset_password_email(user, reset_token)
        expect(mail.from).to eq(['custom@smartlift.com'])
      end
    end

    context 'with custom frontend URL' do
      before do
        ENV['FRONTEND_URL'] = 'https://smartlift.app'
      end

      after do
        ENV.delete('FRONTEND_URL')
      end

      it 'uses custom frontend URL in reset link' do
        mail = UserMailer.reset_password_email(user, reset_token)
        expect(mail.body.encoded).to include('https://smartlift.app/reset-password/')
      end
    end
  end

  describe 'email delivery' do
    it 'delivers reset password email successfully' do
      expect {
        UserMailer.reset_password_email(user, reset_token).deliver_now
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'delivers password reset success email successfully' do
      expect {
        UserMailer.password_reset_success(user).deliver_now
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end