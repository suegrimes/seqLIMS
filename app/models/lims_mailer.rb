class LimsMailer < ActionMailer::Base
  # EMAIL_CREATE[:samples] = 'Prod'  #Create normal production emails
  # EMAIL_CREATE[:samples] = 'Test'  #Create emails to send to admin account
  # EMAIL_CREATE[:samples] = 'Test1' #Create emails to send to admin account, plus email addressses associated with consent protocol
  # EMAIL_CREATE[:samples] = 'None'  #Do not create any emails
  
  def new_sample(sample, mrn, upd_by, emails=nil)
    subject    'Secure: LIMSMailer - New clinical sample'
    recipients email_list(emails)
    from       EMAIL_FROM
    sent_on    Time.now
    body       :sample => sample,
               :mrn => mrn,
               :upd_by => upd_by
  end
  
protected
  def email_list(emails)
    email_to = ((EMAIL_CREATE[:samples] == 'Production' && Rails.env == 'production') ? EMAIL_TO[:samples] : EMAIL_TO[:admin])
    return (emails.nil? ? email_to.split(/, /) : email_to.split(/, /) | emails.split(/, /))
  end
  
end
