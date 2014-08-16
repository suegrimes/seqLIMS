# == Schema Information
#
# Table name: index_tags
#
#  id              :integer          not null, primary key
#  adapter_id      :integer
#  runtype_adapter :string(25)
#  tag_nr          :integer
#  tag_sequence    :string(12)
#  created_at      :datetime
#  updated_at      :timestamp
#

class IndexTag < ActiveRecord::Base
  belongs_to :adapter

  def runtype_adapter
    return self.adapter.runtype_adapter
  end

  def index1_code
     return (self.adapter.index1_prefix.blank? ? tag_nr : [self.adapter.index1_prefix, format('%02d',tag_nr)].join)
  end

  def index2_code
    return (self.adapter.index2_prefix.blank? ? tag_nr : [self.adapter.index2_prefix, format('%02d',tag_nr)].join)
  end

  def tag_ctr
    (runtype_adapter == 'M_HLA192' ? tag_nr - 100 : tag_nr)
  end
  
#  def self.splex_adapters
#    return ["S_SR", "S_PE"]
#  end
  
#  def self.mplex_adapters
#    adapters = self.select(:runtype_adapter).uniq.pluck(:runtype_adapter)
#    #adapters = self.find(:all, :select => "runtype_adapter", :group => 'runtype_adapter').map(&:runtype_adapter)
#    return adapters.unshift("M_SR")
#  end
  
#  def self.find_or_blank(runtype, tag_nr)
#    if tag_nr.nil?
#      return nil
#    else
#      adapter = (runtype == 'M_SR'? 'M_PE' : runtype)
#      index_tag = self.where("runtype_adapter = ? AND tag_nr = ?", adapter, tag_nr).order(:tag_nr).first
#      #index_tag = self.find(:first, :order => :tag_nr,
#      #                       :conditions => ["runtype_adapter = ? AND tag_nr = ?", adapter, tag_nr])
#      return (index_tag.nil? ? ' ' : index_tag.tag_sequence)
#    end
#  end
  
end
