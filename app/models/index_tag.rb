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
end
