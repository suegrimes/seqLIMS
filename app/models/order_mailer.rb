class OrderMailer < ActionMailer::Base
  # EMAIL_CREATE[:orders] = 'Prod'  #Create normal production emails
  # EMAIL_CREATE[:orders] = 'Test'  #Create emails to send to admin account
  # EMAIL_CREATE[:orders] = 'None'  #Do not create any emails
  
  def new_items(items, user)
    subject    'LIMSMailer - New item(s) ordered'
    recipients email_list(items[0].deliver_site, user)
    from       EMAIL_FROM
    sent_on    Time.now
    body       :items => items,
               :user => user
  end
  
protected
  def email_list(deliver_site, user)
    email_to = ((EMAIL_CREATE[:orders] == 'Production' && RAILS_ENV == 'production') ? EMAIL_TO[:orders] : EMAIL_TO[:admin])
    return email_to.split(/, /)
    #user_email = (user.nil? ? nil : user.email)
    #return email_to.split(/, /) | user_email
  end

end
