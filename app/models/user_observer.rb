class UserObserver < ActiveRecord::Observer

#  def after_create(user)
#    UserNotifier.deliver_signup_notification(user)
#  end  
  
  def after_save(user)
    # Rails 2.3x
    #UserNotifier.deliver_activation(user) if user.recently_activated?
    #UserNotifier.deliver_reset_notification(user) if user.recently_reset?

    # Rails 3.x
    #UserNotifier.activation(user).deliver if user.recently_activated?
    UserNotifier.reset_notification(user).deliver if user.recently_reset?
  end
  
end