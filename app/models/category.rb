# == Schema Information
#
# Table name: categories
#
#  id                   :integer(4)      not null, primary key
#  cgroup_id            :integer(4)
#  category             :string(50)      default(""), not null
#  category_description :string(255)
#  archive_flag         :string(1)
#  created_at           :datetime
#  updated_at           :datetime
#

class Category < ActiveRecord::Base
  belongs_to :cgroup
  has_many :category_values
  accepts_nested_attributes_for :category_values, :reject_if => proc {|attrs| attrs[:c_value].blank?},
                                                  :allow_destroy => true
  
  def self.find_and_sortby_cgroup
    self.includes(:cgroup).order("cgroups.sort_order, categories.category").where("archive_flag IS NULL").all
  end
  
  def self.populate_dropdown_for_category(name, output='collection')
    category = self.where("category = ?", name).first
    cat_values = CategoryValue.where("category_id = ?", category.id).order("c_position").all
    if output == 'string'
      return cat_values.map {|m| m.c_value}
    else
      return cat_values
    end  
  end
  
  def self.populate_dropdowns(cgroups=nil)
    condition_array = (cgroups.nil? ? nil : ["categories.cgroup_id IN (?)", cgroups])
    if !cgroups.nil?
      self.includes(:category_values).order("categories.category, category_values.c_position").where(*condition_array).all
    else
      self.includes(:category_values).order("categories.category, category_values.c_position").all
    end
  end
  
end
