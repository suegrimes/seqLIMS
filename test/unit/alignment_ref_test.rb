# == Schema Information
#
# Table name: alignment_refs
#
#  id             :integer          not null, primary key
#  alignment_key  :string(20)       not null
#  interface_name :string(25)
#  genome_build   :string(50)
#  created_by     :integer
#  created_at     :datetime
#  updated_at     :timestamp
#

require 'test_helper'

class AlignmentRefTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
