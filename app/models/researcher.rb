# == Schema Information
#
# Table name: researchers
#
#  id                  :integer(4)      not null, primary key
#  user_id             :integer(4)
#  researcher_name     :string(50)      default(""), not null
#  researcher_initials :string(3)       default(""), not null
#  company             :string(50)
#  phone_number        :string(20)
#  active_inactive     :string(1)
#

class Researcher < ActiveRecord::Base
  belongs_to :user
  
  scope :active, :conditions => {:active_inactive => 'A'}

  def self.populate_dropdown(active_flag='active_only', add_existing = [])
    if active_flag == 'active_only'
      researchers = self.active.order(:researcher_name).pluck(:researcher_name)
    else
      #researchers = self.find(:all, :order => "active_inactive, researcher_name").collect(&:researcher_name)
      researchers = self.order("active_inactive, researcher_name").all.pluck(:researcher_name)
    end
    if add_existing.nil?
      return researchers
    else
      return researchers | add_existing.to_a
    end
  end

  def self.find_and_group_by_active_inactive
    researchers = self.order("researchers.active_inactive, researchers.researcher_name").all
    #researchers = self.find(:all, :order => "researchers.active_inactive, researchers.researcher_name")
    return researchers.group_by {|researcher| researcher.active_inactive}
  end

end
