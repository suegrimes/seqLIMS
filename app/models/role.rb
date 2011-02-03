# == Schema Information
#
# Table name: roles
#
#  id   :integer(4)      not null, primary key
#  name :string(255)
#

class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  
  DEFAULT_ROLE = 'researcher'
  
end
