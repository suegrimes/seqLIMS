class UserNotifier < ActionMailer::Base
  
  default content_type: 'text/html'
  
  def signup_notification(user)
    @user = user
    @url = "#{SITE_URL}/activate/#{user.activation_code}"
    mail(:subject => 'LIMS: Please activate your new account',
	     :from => EMAIL_FROM,
		 :to => user.email)
  end
  
  def activation(user)
    @user = user
    @url = "#{SITE_URL}"
    mail(:subject => 'LIMS: Your account has been activated!',
	     :from => EMAIL_FROM,
		 :to => user.email)
  end
  
  def reset_notification(user)
    @user = user
    @url = "#{SITE_URL}/reset/#{user.reset_code}"
    mail(:subject => 'LIMS: Link to reset your password',
	     :from => EMAIL_FROM,
		 :to => user.email)
  end
end
