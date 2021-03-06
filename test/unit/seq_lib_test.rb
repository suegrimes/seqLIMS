# == Schema Information
#
# Table name: seq_libs
#
#  id                  :integer          not null, primary key
#  barcode_key         :string(20)
#  lib_name            :string(50)       not null
#  library_type        :string(2)
#  lib_status          :string(2)
#  protocol_id         :integer
#  owner               :string(25)
#  preparation_date    :date
#  adapter_id          :integer
#  runtype_adapter     :string(25)
#  project             :string(50)
#  pool_id             :integer
#  oligo_pool          :string(8)
#  alignment_ref_id    :integer
#  alignment_ref       :string(50)
#  trim_bases          :integer
#  sample_conc         :decimal(15, 9)
#  sample_conc_uom     :string(10)
#  lib_conc_requested  :decimal(15, 9)
#  lib_conc_uom        :string(10)
#  notebook_ref        :string(50)
#  notes               :string(255)
#  quantitation_method :string(20)
#  starting_amt_ng     :decimal(11, 3)
#  pcr_size            :integer
#  dilution            :decimal(6, 3)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :timestamp        not null
#

require 'test_helper'

class SeqLibTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
