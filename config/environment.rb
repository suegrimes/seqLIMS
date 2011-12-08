# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  # config.gem "stffn-declarative_authorization", :lib => "declarative_authorization"
  # config.gem "ar-extensions", :version => '0.8.0'
  # config.gem "ezcrypto",      :version => '0.7.2'
    config.gem "ezcrypto"
    config.gem "ar-extensions"
    config.gem "cancan",        :version => '~> 1.6.4'
  # config.gem 'will_paginate', :lib => 'will_paginate', :source => 'http://gems/github.com', :version => '~> 2.3.6'
    config.gem 'calendar_date_select'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  #config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  config.active_record.observers = :user_observer
  
  # Configure action mailer
  config.action_mailer.smtp_settings = {
             :address => 'smtp.stanford.edu',
             :port    => 25,
             :domain  => 'stanford.edu',
             :tls     => true,
             :enable_starttls_auto => true,
#             :authentication => :login,
#             :user_name => 'sgrimes',
#             :password  => '[mypswd]'
             }

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  #config.time_zone = 'UTC'
  
   # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_LIMS_session',
    :secret => '8b7444061d4099e648ec356cd3365acde55cccd3d0331f4a8b21e3c4cda1b7502743f0c7f556cce93e8f6dd8556128e9c5db06d63c8ebf64ee74bf84d8930c8c'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

# Date/Time formating for CalendarDateSelect
  CalendarDateSelect.format = :iso_date
