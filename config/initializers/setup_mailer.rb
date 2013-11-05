# Configure action_mailer
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
    :address              => 'smtp.stanford.edu',
    :port                 => 25,
    :domain               => 'stanford.edu',
    :enable_starttls_auto => true
}