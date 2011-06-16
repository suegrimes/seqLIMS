class OrderMailer < ActionMailer::Base
  # MAIL_FLAG = 'Prod'  #Normal production emails sent out when item entered
  # MAIL_FLAG = 'Test'  #Emails sent only to admin email, when item entered
  # MAIL_FLAG = 'Dev'   #Logic in controller to not send or display any emails
  
  # DELIVER_FLAG = 'Debug'   # Displays email as text in browser window
  # DELIVER_FLAG = 'Deliver' # Delivers email normally
  # DELIVER_FLAG = 'None'    # No email delivered
  
  MAIL_FLAG = 'Test'
  DELIVER_FLAG = 'Deliver'
  
  TO_EMAIL_ADMIN   = ['sgrimes@stanford.edu']
  TO_EMAIL_CCSR    = ['drgalvez@stanford.edu']
  TO_EMAIL_SGTC    = ['jennyzh@stanford.edu']
  FROM_EMAIL       = 'sgtc_lims@stanford.edu'
  
  def new_items(items, user)
    subject    'LIMSMailer - New item(s) ordered'
    recipients email_list(MAIL_FLAG, items[0].deliver_site, user)
    from       FROM_EMAIL
    sent_on    Time.now
    body       :items => items,
               :user => user
  end
  
protected
  def email_list(mail_flag, deliver_site, user)
    if (mail_flag == 'Prod' && RAILS_ENV == 'production')
      emails = all_emails(deliver_site, user)    
    else
      emails = TO_EMAIL_ADMIN  
    end
    return emails
  end
  
  def all_emails(deliver_site, user)
    order_email = (deliver_site == 'SGTC' ? TO_EMAIL_SGTC : TO_EMAIL_CCSR)
    #entry_email = (user.nil? ? nil : user.email)
    entry_email = nil
    return order_email | entry_email | TO_EMAIL_ADMIN
  end
  
end
