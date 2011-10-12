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
    adapter = (runtype == 'M_SR'? 'M_PE' : runtype)
    tag_nrs = tag_nr.split(',').sort 
    index_tags = self.find(:all, :order => :tag_nr,
                           :conditions => ["runtype_adapter = ? AND tag_nr IN (?)", adapter, tag_nrs])
    return (index_tags.nil? ? ' ' : index_tags.map{|tag| tag.tag_sequence}.join(','))
  end
end
