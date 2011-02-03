# == Schema Information
#
# Table name: cgroups
#
#  id         :integer(4)      not null, primary key
#  group_name :string(25)      default(""), not null
#  sort_order :integer(2)
#  created_at :datetime
#  updated_at :timestamp
#

# == Schema Information
#
# Table name: cgroups
#
#  id         :integer(4)      not null, primary key
#  group_name :string(25)      default(""), not null
#  sort_order :integer(2)
#  created_at :datetime
#  updated_at :timestamp
#
#
class Cgroup < ActiveRecord::Base
  has_many :categories
  
  CGROUPS = {'Clinical'    => '1',
             'Sample'      => '2',
             'Extraction'  => '3',
             'Seq Library' => '4',
             'Sequencing'  => '5',
             'Pathology'   => '6',
             'Histology'   => '7'}
  
end
