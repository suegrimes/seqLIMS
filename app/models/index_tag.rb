# == Schema Information
#
# Table name: index_tags
#
#  id              :integer          not null, primary key
#  adapter_id      :integer
#  runtype_adapter :string(25)
#  index_read      :integer
#  tag_nr          :integer
#  tag_sequence    :string(12)
#  created_at      :datetime
#  updated_at      :timestamp
#

class IndexTag < ActiveRecord::Base
  belongs_to :adapter

  def adapter_name
    return self.adapter.runtype_adapter
  end

  def index1_code
     return (self.adapter.index1_prefix.blank? ? tag_nr : [self.adapter.index1_prefix, format('%02d',tag_nr)].join)
  end

  def index2_code
    return (self.adapter.index2_prefix.blank? ? tag_nr : [self.adapter.index2_prefix, format('%02d',tag_nr)].join)
  end

  def index_code
    return (index_read == 2 ? index2_code : index1_code)
  end

  def tag_ctr
    (runtype_adapter == 'M_HLA192' ? tag_nr - 100 : tag_nr)
  end

end

