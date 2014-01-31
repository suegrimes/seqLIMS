# == Schema Information
#
# Table name: run_dirs
#
#  id                :integer          not null, primary key
#  flow_cell_id      :integer          not null
#  sequencing_key    :string(50)
#  storage_device_id :integer          not null
#  device_name       :string(25)
#  rdir_name         :string(50)
#  file_count        :integer
#  total_size_gb     :decimal(6, 2)
#  date_sized        :date
#  date_copied       :date
#  copied_by         :integer
#  date_verified     :date
#  verified_by       :integer
#  delete_flag       :string(1)
#  date_deleted      :date
#  notes             :string(255)
#  updated_by        :integer
#  updated_at        :timestamp
#

class RunDir < ActiveRecord::Base
  belongs_to :storage_device
  belongs_to :flow_cell
  
  validates_uniqueness_of :storage_device_id, :scope => :flow_cell_id, :message => 'already exists for this sequencing run'
  validates_date :date_sized, :date_copied, :date_verified, :allow_blank => true
  
  before_save :derive_field_vals

  def derive_field_vals
    self.device_name    = self.storage_device.device_name
    self.sequencing_key = self.flow_cell.sequencing_key 
  end
end
