# == Schema Information
#
# Table name: pools
#
#  id                  :integer(4)      not null, primary key
#  pool_name           :string(50)      default(""), not null
#  tube_label          :string(50)
#  enzyme_code         :string(20)      default(""), not null
#  pool_description    :string(255)
#  source_conc_um      :decimal(6, 1)
#  pool_volume         :decimal(9, 3)   default(0.0)
#  project_id          :integer(4)
#  storage_location_id :integer(4)
#  comments            :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#

class Pool < ActiveRecord::Base
  establish_connection (:oligo_inventory)
end
