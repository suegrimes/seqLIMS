# == Schema Information
#
# Table name: freezer_locations
#
#  id          :integer          not null, primary key
#  room_nr     :string(25)       default(""), not null
#  freezer_nr  :string(25)
#  owner_name  :string(25)
#  owner_email :string(50)
#  comments    :string(255)
#  created_at  :datetime
#  updated_at  :timestamp        not null
#

class FreezerLocation < ActiveRecord::Base
  #has_many :samples
  #has_many :processed_samples
  has_many :sample_storage_containers
  
  #validates_uniqueness_of :location_string
  
  def room_and_freezer
    name_array      = owner_name.split(' ')
    last_nm         = (owner_name.nil? ? ' ' : name_array[-1])
    last_nm_wparens = (last_nm.blank? ? ' ' : ['(', last_nm, ')'].join)
    return [[room_nr, freezer_nr].join('/'), last_nm_wparens].join
  end
  
  def self.list_all_by_room
    self.order(:room_nr, :freezer_nr).all
    #self.find(:all, :order => 'freezer_locations.room_nr, freezer_locations.freezer_nr')
  end
end
