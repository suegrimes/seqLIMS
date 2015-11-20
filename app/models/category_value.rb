# == Schema Information
#
# Table name: category_values
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  c_position  :integer
#  c_value     :string(50)       not null
#  created_at  :datetime
#  updated_at  :datetime
#

class CategoryValue < ActiveRecord::Base
  belongs_to :category
  
  def self.populate_dropdown_for_id(category_id)
    self.where(:category_id => category_id).order(:c_position).all
  end

  def cq_position
    # Make [Unknown] value sort to bottom of drop-down lists for queries
    c_value == '[Unknown]' ? 99 : c_position
  end
  
end
