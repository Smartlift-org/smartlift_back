class ApplicationMailer < ActionMailer::Base
  default from: ENV['SMTP_FROM_EMAIL'] || 'noreply@smartlift.com'
  layout "mailer"
end
