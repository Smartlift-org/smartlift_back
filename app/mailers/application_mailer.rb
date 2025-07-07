class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('SMTP_FROM_EMAIL', 'noreply@smartlift.com')
  layout "mailer"
end
