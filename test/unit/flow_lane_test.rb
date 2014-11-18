# == Schema Information
#
# Table name: flow_lanes
#
#  id               :integer          not null, primary key
#  flow_cell_id     :integer          not null
#  seq_lib_id       :integer
#  sequencing_key   :string(50)
#  machine_type     :string(10)
#  lib_barcode      :string(20)
#  lib_name         :string(50)
#  lane_nr          :integer          not null
#  lib_conc         :float(11)
#  lib_conc_uom     :string(6)
#  adapter_id       :integer
#  runtype_adapter  :string(20)
#  pool_id          :integer
#  oligo_pool       :string(8)
#  alignment_ref_id :integer
#  alignment_ref    :string(50)
#  notes            :string(255)
#  created_at       :datetime
#  updated_at       :timestamp
#

require 'test_helper'

class FlowLaneTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
