# == Schema Information
#
# Table name: sample_storage_containers
#
#  id                     :integer          not null, primary key
#  stored_sample_id       :integer
#  stored_sample_type     :string(50)
#  sample_name_or_barcode :string(25)       default(""), not null
#  container_type         :string(10)
#  container_name         :string(25)       default(""), not null
#  position_in_container  :string(15)
#  freezer_location_id    :integer
#  storage_container_id   :integer
#  row_nr                 :string(2)
#  position_nr            :string(3)        default("")
#  notes                  :string(100)
#  updated_by             :integer
#  updated_at             :timestamp
#

class SampleStorageContainer < ActiveRecord::Base
  belongs_to :freezer_location
  belongs_to :stored_sample, :polymorphic => true

  before_create :upd_sample_name
  before_update :upd_stored_sample, :if => :sample_name_or_barcode_changed?

  validates_presence_of :sample_name_or_barcode

  def upd_sample_name
    self.sample_name_or_barcode = self.stored_sample.barcode_key
  end

  def upd_stored_sample
    if lib_or_sample_type == 'L'
      self.stored_sample = SeqLib.where('barcode_key = ?', self.sample_name_or_barcode).first
    elsif lib_or_sample_type = 'S'
      self.stored_sample = Sample.where('barcode_key = ?', self.sample_name_or_barcode).first
    elsif ['D', 'R', 'N', 'P'].include?(lib_or_sample_type)
      self.stored_sample = ProcessedSample.where('barcode_key = ?', self.sample_name_or_barcode).first
    else
      self.stored_sample = nil
    end
  end

  def lib_or_sample_type
    if sample_name_or_barcode[0,1] == 'L' and sample_name_or_barcode[1..-1].to_i > 0
      return 'L'
    else
      barcode_split = sample_name_or_barcode.split('.')
      if barcode_split.length == 1
        return 'S'
      else
        return barcode_split[-1][0,1] # first character of last substring after splitting by '.'
      end
    end
  end

  def type_of_sample
    stype = 'NotInLIMS'
    if stored_sample
      if stored_sample_type == 'Sample'
        stype = stored_sample.sample_type
      elsif stored_sample_type == 'ProcessedSample'
        stype = stored_sample.extraction_type
      else
        stype = stored_sample_type
      end
    end
    return stype
  end

  def container_desc
    [container_type, container_name].join(': ')
  end

  def container_sort
    (container_name =~ /\A\d\Z/ ? '0' + container_name : container_name)
  end
  
  def container_and_position
    [container_desc, position_in_container].join('/')
  end
  
  def position_sort
    if position_in_container =~ /\A[A-Z]\d+\Z/ 
      sort1 = position_in_container[0,1]
      sort2 = position_in_container[1..-1].to_i
    else
      sort1 = (position_in_container.nil? ? '' : position_in_container)
      sort2 = 0
    end
    return [sort1, sort2] 
  end
  
  def room_and_freezer
    (freezer_location ? freezer_location.room_and_freezer : '')
  end

  def self.find_for_query(condition_array)
    self.includes(:freezer_location).where(sql_where(condition_array))
        .order('freezer_locations.freezer_nr, freezer_locations.room_nr, container_type, container_name').all
  end

  def self.find_for_export(container_ids)
    self.find_for_query(["sample_storage_containers.id IN (?)", container_ids])
  end

  def self.populate_dropdown
    self.where('container_type > ""').order(:container_type).uniq.pluck(:container_type)
  end
end
