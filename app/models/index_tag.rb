# == Schema Information
#
# Table name: index_tags
#
#  id              :integer(4)      not null, primary key
#  runtype_adapter :string(25)
#  tag_nr          :integer(2)
#  tag_sequence    :string(12)
#  created_at      :datetime
#  updated_at      :timestamp
#

class IndexTag < ActiveRecord::Base
  def self.find_or_blank(runtype, tag_nr) 
    if tag_nr.nil?
      return nil
    else
      adapter = (runtype == 'M_SR'? 'M_PE' : runtype)
      index_tag = self.find(:first, :order => :tag_nr,
                             :conditions => ["runtype_adapter = ? AND tag_nr = ?", adapter, tag_nr])
      return (index_tag.nil? ? ' ' : index_tag.tag_sequence)
    end   
  end
  
  def self.adapter_sort
    case runtype_adapter
      when 'M_7BR1'        then 1
      when 'M_PE_SS3rd'    then 2
      when 'M_PE'          then 3
      when 'M_PE_Illumina' then 4
      else 9
    end
  end
end
