# == Schema Information
#
# Table name: align_qc
#
#  id                       :integer          not null, primary key
#  flow_lane_id             :integer          not null
#  sequencing_key           :string(50)
#  lane_nr                  :integer
#  lane_yield               :integer
#  clusters_raw             :integer
#  clusters_pf              :integer
#  cycle1_intensity_pf      :integer
#  cycle20_intensity_pct_pf :integer
#  pct_pf_clusters          :decimal(6, 2)
#  pct_align_pf             :decimal(6, 2)
#  align_score_pf           :decimal(8, 2)
#  pct_error_rate_pf        :decimal(6, 2)
#  nr_NM                    :integer
#  nr_QC                    :integer
#  nr_RX                    :integer
#  nr_U0                    :integer
#  nr_U1                    :integer
#  nr_U2                    :integer
#  nr_UM                    :integer
#  nr_nonuniques            :integer
#  nr_uniques               :integer
#  min_insert               :integer
#  max_insert               :integer
#  median_insert            :integer
#  total_reads              :integer
#  pf_reads                 :integer
#  failed_reads             :integer
#  total_errors             :integer
#  consistent_unique_bp     :integer
#  consistent_unique_pct    :decimal(4, 1)
#  rescued_bp               :integer
#  rescued_pct              :decimal(4, 1)
#  total_consistent_bp      :integer
#  total_consistent_pct     :decimal(4, 1)
#  pf_unique_bp             :integer
#  pf_unique_pct            :decimal(4, 1)
#  notes                    :string(255)
#  created_at               :datetime
#  updated_at               :timestamp
#

require 'test_helper'

class AlignQcTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
