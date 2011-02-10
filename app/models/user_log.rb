# == Schema Information
#
# Table name: user_logs
#
#  id              :integer(4)      not null, primary key
#  ip_address      :string(20)
#  user_id         :integer(2)
#  user_login      :string(25)      default(""), not null
#  controller_name :string(25)      default(""), not null
#  action_name     :string(25)      default(""), not null
#  log_timestamp   :datetime        not null
#


class UserLog < ActiveRecord::Base
  # LOG_LEVEL = 'login':  Log only login/logout activity (user_logins table)
  # LOG_LEVEL = 'all'  :  Log access to all controllers/methods (user_logs table)
  # LOG_LEVEL = 'none' :  No logging
  LOG_LEVEL = 'all'
  
  def self.add_entry(controller, current_user, ip_address)
    return if LOG_LEVEL == 'none'
    
    # Add login/logout entry (WelcomeController); LOG_LEVEL != 'none'
    if controller.controller_name == 'welcome'
      if ['user_login', 'add_user'].include?(controller.action_name)
        UserLogin.add_entry('login', current_user, ip_address)
      elsif controller.action_name == 'logout'
        UserLogin.add_entry('logout', current_user, ip_address)
      end
    end
    
    # Add detailed log entry (any controller/action); LOG_LEVEL == 'all'
    UserLog.create(:ip_address      => ip_address,
                   :user_id         => (current_user.nil? ?  nil  : current_user.id),
                   :user_login      => (current_user.nil? ? 'nil' : current_user.login),
                   :controller_name => controller.controller_name,
                   :action_name     => controller.action_name,
                   :log_timestamp   => Time.now)              if LOG_LEVEL == 'all' 
  end
  
end
