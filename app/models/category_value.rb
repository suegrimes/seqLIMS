# == Schema Information
#
# Table name: category_values
#
#  id          :integer(4)      not null, primary key
#  category_id :integer(4)      not null
#  c_position  :integer(4)
#  c_value     :string(50)      default(""), not null
#  created_at  :datetime
#  updated_at  :datetime
#

class CategoryValue < ActiveRecord::Base
  belongs_to :category
  
  def self.populate_dropdown_for_id(category_id)
    self.find_all_by_category_id(category_id, :order => :c_position)
  end
  
end
