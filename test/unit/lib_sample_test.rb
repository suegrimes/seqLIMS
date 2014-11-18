# == Schema Information
#
# Table name: lib_samples
#
#  id                  :integer          not null, primary key
#  seq_lib_id          :integer
#  splex_lib_id        :integer
#  splex_lib_barcode   :string(20)
#  processed_sample_id :integer
#  sample_name         :string(50)
#  source_DNA          :string(50)
#  runtype_adapter     :string(50)
#  index_tag           :integer
#  adapter_id          :integer
#  index1_tag_id       :integer
#  index2_tag_id       :integer
#  enzyme_code         :string(50)
#  notes               :string(255)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :timestamp
#

require 'test_helper'

class LibSampleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
