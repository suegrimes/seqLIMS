# == Schema Information
#
# Table name: storage_devices
#
#  id               :integer          not null, primary key
#  device_name      :string(25)       default(""), not null
#  building_loc     :string(25)
#  base_run_dir     :string(50)
#  last_upd_of_runs :date
#  updated_by       :integer
#  updated_at       :timestamp
#

class StorageDevice < ActiveRecord::Base
  has_many :run_dirs
  
  def self.populate_dropdown
    storage_devices = self.order(:device_name).all
    #storage_devices = self.find(:all, :order => :device_name)
  end
end
