class OrderMailer < ActionMailer::Base
  # EMAIL_CREATE[:orders] = 'Prod'  #Create normal production emails
  # EMAIL_CREATE[:orders] = 'Test'  #Create emails to send to admin account
  # EMAIL_CREATE[:orders] = 'None'  #Do not create any emails
  
  def new_items(items, user)
    subject    'LIMSMailer - New item(s) ordered'
    recipients email_list(items[0].deliver_site)
    from       EMAIL_FROM
    sent_on    Time.now
    body       :items => items,
               :user => user
  end
  
protected
  def email_list(deliver_site)
    #Use orders email fields specific to delivery site if they exist, otherwise use generic 'orders' email fields
    email_create_orders = email_value(EMAIL_CREATE, 'orders', deliver_site)
    email_to_orders = email_value(EMAIL_TO, 'orders', deliver_site)
    
    email_to = ((email_create_orders == 'Production' && RAILS_ENV == 'production') ? email_to_orders : EMAIL_TO[:admin])
    return email_to.split(/, /)
    
    #user_email = (user.nil? ? nil : user.email)
    #return email_to.split(/, /) | user_email
  end
  
  def email_value(email_hash, email_type, deliver_site)
    site_and_type = [deliver_site, email_type].join('_')
    return (email_hash[site_and_type.to_sym].nil? ? email_hash[email_type.to_sym] : email_hash[site_and_type.to_sym])
  end

end
