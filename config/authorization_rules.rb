# Authorization rules for declarative authorization.  Delete this after transitioning
# to cancan

authorization do
  role :admin do
    has_permission_on :users, :to => [:read, :manage]
  end
  
  role :clin_admin do
    has_permission_on :users, :to => [:read, :manage] do
      if_attribute :role => 'clin_admin'
    end
  end

  role :guest do
    has_permission_on :users, :to => [:new, :create]
  end
  
end

privileges do
  privilege :read do
    includes :index, :show
  end
  privilege :manage do
    includes :new, :create, :edit, :update, :delete
  end
end