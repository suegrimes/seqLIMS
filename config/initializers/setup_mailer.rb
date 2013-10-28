# Configure action_mailer
ActionMailer::Base.smtp_settings = {
    :address              => 'smtp.stanford.edu',
    :port                 => 25,
    :domain               => 'stanford.edu',
    :tls                  => true,
    :enable_starttls_auto => true
}