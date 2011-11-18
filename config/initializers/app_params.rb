environment_file = "#{RAILS_ROOT}/public/system/environment.txt"
email_file       = "#{RAILS_ROOT}/public/system/emails.txt"
ezkeys_file      = "#{RAILS_ROOT}/public/system/ez_keys.txt"
version_file     = "#{RAILS_ROOT}/public/app_versions.txt"

require 'fastercsv'

if FileTest.file?(environment_file)
  env_array = FasterCSV.read(environment_file, {:col_sep => "\t"})
  APP_TYPE = env_array[0][0][0..3].upcase
  SITE_URL = env_array[0][1]
end

DEMO_APP = (APP_TYPE == 'DEMO'? true : false)
DEMO_USERS = ['admin', 'clinical', 'researcher']

#Email configuration parameters #
#Contents of .txt file (tab-delimited) expected to be: 
# Send_From <Email>               where <Email> is email address to be used for sending emails from the system
# Admin_To  <Email>               where <Email> is email address of system admin (debug emails will be sent here)

# Samples_Email <Env>             where <Env> is either Production, Test, or NoEmail
# Samples_Delivery  <Delivery>    where <Delivery> is Deliver, Debug or None
# Samples_To  <Email>             where <Email> is an array of email addresses to which new samples should be sent

# Orders_Email <Env>              where <Env> is either Production, Test, or NoEmail
# Orders_Delivery <Delivery>      where <Delivery> is Deliver, Debug or None
# Orders_To <Email>               where <Email> is an array of email addresses to which new orders should be sent

EMAIL_CREATE = {}
EMAIL_TO = {}
EMAIL_DELIVERY = {}

if FileTest.file?(email_file)
  FasterCSV.foreach(email_file, {:col_sep => "\t"}) do |erow|
    case
    when erow[0] == 'Send_From'
      EMAIL_FROM = erow[1]
    when erow[0].match(/_Email/)
      EMAIL_CREATE.merge!(erow[0].split('_')[0].downcase.to_sym => erow[1])
    when erow[0].match(/_To/)
      EMAIL_TO.merge!(erow[0].split('_')[0].downcase.to_sym => erow[1])
    when erow[0].match(/_Delivery/)
      EMAIL_DELIVERY.merge!(erow[0].split('_')[0].downcase.to_sym => erow[1])
    end
  end
end

#read keys for ezcrypto encryption/decryption
ez_arr = IO.readlines(ezkeys_file)
EZ_PSWD = ez_arr[0].chomp
EZ_SALT = ez_arr[1].chomp

#read App_Versions file to set current application version #
#version# is first row, first column
if FileTest.file?(version_file)
  File.open(version_file) do |file|
    filerow = file.gets
    APP_VERSION = filerow.split(/\t/)[0]
    file.close
  end
end

META_TAGS = {:description => "Stanford Genome Technology LIMS manages clinical samples, molecular assays and other processing related to high throughput resequencing operations",
             :keywords => ["stanford, LIMS, biological medicine, hanlee ji, genome, cancer, cancer research, dna sequencing"]}
