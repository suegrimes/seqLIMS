# == Schema Information
#
# Table name: target_pools
#
#  id         :integer(4)      not null, primary key
#  pool_name  :string(20)      default(""), not null
#  project    :string(25)      default(""), not null
#  enzymes    :string(50)
#  created_at :datetime
#  updated_at :timestamp
#

class TargetPool < ActiveRecord::Base
  def name_project
    (project == 'NA' ? pool_name : [pool_name, project].join('_'))
  end
end
