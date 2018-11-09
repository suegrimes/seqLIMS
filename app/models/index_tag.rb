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

  WELL_LETTER = %w{A B C D E F G H}

  def adapter_name
    return self.adapter.runtype_adapter
  end

  def index1_code
    return (self.adapter.index1_prefix.blank? ? format_tag(tag_nr) : format_index(self.adapter.index1_prefix, tag_nr))
  end

  def index2_code
    return (self.adapter.index2_prefix.blank? ? format_tag(tag_nr) : format_index(self.adapter.index2_prefix, tag_nr))
  end

  def format_index(prefix, tag_nr)
    #if adapter_name =~ /M_10X_.*Plate/ or adapter_name =~ /M_10nt_Illumina.*/
	  if Adapter::PLATE_FORMAT_ADAPTERS.include?(adapter_name)
      well_coords = format_tag(tag_nr)
      return [prefix, '-',well_coords].join
    else
      return [prefix, format('%02d', tag_nr)].join
    end
  end

  def format_tag(tag_nr)
    if Adapter::PLATE_FORMAT_ADAPTERS.include?(adapter_name)
      well_alpha = WELL_LETTER[(tag_nr - 1)/12]
      well_num   = (tag_nr - 1) % 12 + 1
      return [well_alpha + well_num.to_s].join
    else
      return tag_nr
    end
  end

  def index_code
    return (index_read == 2 ? index2_code : index1_code)
  end

  def tag_ctr
    (runtype_adapter == 'M_HLA192' ? tag_nr - 100 : tag_nr)
  end

  def self.find_tag_id(adapter_id, readnr, tag_nr)
    index_tag = self.where('adapter_id = ? AND index_read = ? AND tag_nr = ?', adapter_id, readnr, tag_nr).first
    return (index_tag.nil? ? nil : index_tag.id)
  end

  def self.i2id_for_i1tag(i1id)
    i1tag = self.find(i1id)
    i2tag_id =  (i1tag.nil? ? nil : self.where('adapter_id = ? and index_read = 2 and tag_nr = ?', i1tag.adapter_id, i1tag.tag_nr).pluck(:id))
    return (i2tag_id.nil? ? nil : i2tag_id[0])
  end

end

