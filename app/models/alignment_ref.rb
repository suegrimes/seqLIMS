# == Schema Information
#
# Table name: alignment_refs
#
#  id             :integer          not null, primary key
#  alignment_key  :string(20)       default(""), not null
#  interface_name :string(25)
#  genome_build   :string(50)
#  created_by     :integer
#  created_at     :datetime
#  updated_at     :timestamp
#

class AlignmentRef < ActiveRecord::Base
  DEFAULT_REF = 'HWG_37.1'
  
  def self.default_id
    self.where(:alignment_key => DEFAULT_REF).pluck(:id).first
  end
  
  def self.find_and_sort_all
    self.order("alignment_key").all
  end
  
  def self.populate_dropdown
    self.find_and_sort_all
  end
  
  def self.get_align_key(id=nil)
    return nil if id.nil?
    self.find(id).alignment_key
  end
end
