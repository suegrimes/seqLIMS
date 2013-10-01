# == Schema Information
#
# Table name: sample_containers
#
#  id                     :integer(4)      not null, primary key
#  stored_sample_id       :integer(4)
#  stored_sample_type     :string(50)
#  sample_name_or_barcode :string(25)      default(""), not null
#  container_type         :string(10)
#  container_name         :string(20)      default(""), not null
#  position_in_container  :string(15)
#  freezer_location_id    :integer(4)
#  storage_container_id   :integer(4)
#  row_nr                 :string(2)
#  position_nr            :string(3)       default("")
#  notes                  :string(100)
#  updated_by             :integer(2)
#  updated_at             :timestamp
#

class SampleStorageContainer < ActiveRecord::Base
  belongs_to :freezer_location
  belongs_to :stored_sample, :polymorphic => true
  
  def before_create
    self.sample_name_or_barcode = self.stored_sample.barcode_key
  end
  
  def container_desc
    [container_type, container_name].join(': ')
  end
  
  def container_and_position
    [container_desc, position_in_container].join('/')
  end
  
  def position_sort
    if position_in_container =~ /\A[A-Z]\d+\Z/ 
      sort1 = position_in_container[0,1]
      sort2 = position_in_container[1..-1].to_i
    else
      sort1 = position_in_container
      sort2 = 0
    end
    return [sort1, sort2] 
  end
  
  def room_and_freezer
    (freezer_location ? freezer_location.room_and_freezer : '')
  end
  
  def self.populate_dropdown
    self.find(:all, :select => 'DISTINCT container_type', :order => 'container_type',
                    :conditions => 'container_type > ""').map(&:container_type)
  end
end
