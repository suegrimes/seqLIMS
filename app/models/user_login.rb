# == Schema Information
#
# Table name: user_logins
#
#  id               :integer(4)      not null, primary key
#  ip_address       :string(20)      default(""), not null
#  user_id          :integer(2)
#  user_login       :string(25)      default(""), not null
#  login_timestamp  :datetime
#  logout_timestamp :datetime
#


class UserLogin < ActiveRecord::Base
  def self.add_entry(login_out, current_user, ip_address)
    user_id = (current_user.nil? ? nil : current_user.id)
    
    # Add login entry
    if login_out == 'login'
      UserLogin.create(:ip_address      => ip_address,
                       :user_id         => user_id,
                       :user_login      => (current_user.nil? ? 'nil' : current_user.login),
                       :login_timestamp => Time.now)
    end
    
    # Upd most recent login, with logout time
    if login_out == 'logout'
      user_login = UserLogin.find(:first,
                                  :conditions => ["user_id = ? AND ip_address = ?", user_id, ip_address],
                                  :order => "login_timestamp DESC")
      if user_login
        user_login.update_attributes(:logout_timestamp => Time.now)
      else
        UserLogin.create(:ip_address       => ip_address,
                         :user_id          => user_id,
                         :user_login       => (current_user.nil? ? 'nil' : current_user.login),
                         :logout_timestamp => Time.now)
      end
    end    
  end
  
end
