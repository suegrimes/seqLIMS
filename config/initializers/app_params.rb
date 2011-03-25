version_file     = "#{RAILS_ROOT}/public/app_versions.txt"
email_file       = "#{RAILS_ROOT}/public/system/emails.txt"
ezkeys_file      = "#{RAILS_ROOT}/public/system/ez_keys.txt"
environment_file = "#{RAILS_ROOT}/public/system/environment.txt"

app_type = 'PROD'
if FileTest.file?(environment_file)
  demo_app = IO.readlines(environment_file)
  app_type = demo_app[0].chomp
end

DEMO_APP = (app_type == 'DEMO'? true : false)
DEMO_USERS = ['admin', 'clinical', 'researcher']

#read App_Versions file to set current application version #
#version# is first row, first column
if FileTest.file?(version_file)
  File.open(version_file) do |file|
    filerow = file.gets
    APP_VERSION = filerow.split(/\t/)[0]
    file.close
  end
end

#read keys for ezcrypto encryption/decryption
ez_arr = IO.readlines(ezkeys_file)
EZ_PSWD = ez_arr[0].chomp
EZ_SALT = ez_arr[1].chomp

#populate array of email addresses from email_file #
#EMAILS will populate drop-down list of email addresses to send confirmation of new samples to
# No longer used?  (Use email address(es) associated with protocols instead)
EMAILS = []
if FileTest.file?(email_file)
  File.open(email_file) do |file|
    while filerow = file.gets
      EMAILS.push(filerow.chomp.split(/\t/)[0])
    end
    file.close
  end
end

META_TAGS = {:description => "Stanford Genomee Technology LIMS manages clinical samples, molecular assays and other processing related to high throughput resequencing operations",
             :keywords => ["stanford, biological medicine, hanlee ji, genome, cancer, cancer research, dna sequencing"]}
