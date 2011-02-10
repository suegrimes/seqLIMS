# == Schema Information
#
# Table name: alignment_refs
#
#  id             :integer(4)      not null, primary key
#  alignment_key  :string(20)      default(""), not null
#  interface_name :string(25)
#  genome_build   :string(50)
#  created_by     :integer(4)
#  created_at     :datetime
#  updated_at     :timestamp
#

class AlignmentRef < ActiveRecord::Base
  
  def self.find_and_sort_all
    self.find(:all, :order => :alignment_key)
  end
  
  def self.populate_dropdown
    self.find_and_sort_all
  end
  
  def self.get_align_key(id=nil)
    return nil if id.nil?
    self.find(id).alignment_key 
  end
end
