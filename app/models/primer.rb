# == Schema Information
#
# Table name: primers
#
#  id                  :integer(4)      not null, primary key
#  pool_name           :string(35)      default(""), not null
#  tube_label          :string(15)      default(""), not null
#  pool_description    :string(80)
#  from_pools          :string(100)
#  from_plates         :string(100)
#  total_oligos        :integer(4)      default(0), not null
#  cherrypick_oligos   :integer(4)      default(0), not null
#  enzyme_code         :string(50)
#  source_conc_um      :decimal(8, 3)
#  pool_volume         :decimal(8, 3)
#  project_id          :integer(2)
#  storage_location_id :integer(2)
#  notes               :string(255)
#  updated_at          :timestamp
#

class Primer < InventoryDB
  has_and_belongs_to_many :pools
  validates_presence_of :primer_name
  validates_uniqueness_of :primer_name
end
