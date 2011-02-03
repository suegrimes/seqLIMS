class LimsMailer < ActionMailer::Base
  # MAIL_FLAG = 'Prod'  #Normal production emails sent out when sample entered
  # MAIL_FLAG = 'Test1' #Emails sent to test email account, when sample entered
  # MAIL_FLAG = 'Test2' #Emails sent to test email account, plus email associated with consent protocol, when sample entered
  # MAIL_FLAG = 'Dev'   #Logic in controller to not send or display any emails
  
  # DELIVER_FLAG = 'Debug'   # Displays email as text in browser window
  # DELIVER_FLAG = 'Deliver' # Delivers email normally
  
  # Default environment to PROD, override with environment_file (/public/system/environment.txt)
  env_type = 'PROD'
  ENVIRONMENT_FILE = File.join(RAILS_ROOT, 'public', 'system', 'environment.txt')
  
  if FileTest.file?(ENVIRONMENT_FILE)
    demo_app = IO.readlines(ENVIRONMENT_FILE)
    env_type = demo_app[0].chomp
  end
  
  MAIL_FLAG = (env_type == 'DEMO'? 'Test1' : 'Prod')
  DELIVER_FLAG = 'Deliver'
  
  TO_EMAIL_SAMPLE_TEST   = ['sgrimes@stanford.edu']
  TO_EMAIL_SAMPLE_PROD   = ['genomics_ji@stanford.edu']
  FROM_EMAIL             = 'sgtc_lims@stanford.edu'
  
  def new_sample(sample_characteristic, mrn, upd_by, emails=nil)
    subject    'Secure: LIMSMailer - New clinical sample'
    recipients email_list(MAIL_FLAG, emails)
    from       FROM_EMAIL
    sent_on    Time.now
    body       :sample_characteristic => sample_characteristic,
               :mrn => mrn,
               :upd_by => upd_by
  end
  
protected
  def email_list(mail_flag, emails)
    use_prod_email = (mail_flag == 'Prod' && RAILS_ENV == 'production')
    std_email      = (use_prod_email == true ? TO_EMAIL_SAMPLE_PROD : TO_EMAIL_SAMPLE_TEST)
    all_emails     = (emails.nil? ? std_email : std_email | emails.split(/, /))
    return all_emails
  end
  
end
