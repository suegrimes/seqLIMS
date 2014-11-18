# == Schema Information
#
# Table name: flow_cells
#
#  id              :integer          not null, primary key
#  flowcell_date   :date
#  nr_bases_read1  :string(4)
#  nr_bases_index  :string(2)
#  nr_bases_index1 :string(2)
#  nr_bases_index2 :string(2)
#  nr_bases_read2  :string(4)
#  cluster_kit     :string(10)
#  sequencing_kit  :string(10)
#  flowcell_status :string(2)
#  sequencing_key  :string(50)
#  run_description :string(80)
#  sequencing_date :date
#  seq_machine_id  :integer
#  seq_run_nr      :integer
#  machine_type    :string(10)
#  hiseq_xref      :string(50)
#  notes           :string(255)
#  created_at      :datetime
#  updated_at      :timestamp        not null
#

require 'test_helper'

class FlowCellTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
