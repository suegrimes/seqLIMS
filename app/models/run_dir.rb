# == Schema Information
#
# Table name: run_dirs
#
#  id                :integer(4)      not null, primary key
#  flow_cell_id      :integer(4)      not null
#  sequencing_key    :string(50)
#  storage_device_id :integer(2)      not null
#  device_name       :string(25)
#  file_count        :integer(4)
#  total_size_gb     :decimal(6, 2)
#  date_sized        :date
#  date_copied       :date
#  copied_by         :integer(2)
#  date_verified     :date
#  verified_by       :integer(2)
#  notes             :string(255)
#  updated_by        :integer(2)
#  updated_at        :timestamp
#

class RunDir < ActiveRecord::Base
  belongs_to :storage_device
  belongs_to :flow_cell
  
  validates_uniqueness_of :storage_device_id, :scope => :flow_cell_id, :message => 'already exists for this sequencing run'
  validates_date :date_sized, :date_copied, :date_verified, :allow_blank => true
  
  def before_save
    self.device_name    = self.storage_device.device_name
    self.sequencing_key = self.flow_cell.sequencing_key 
  end
end
