# == Schema Information
#
# Table name: consent_protocols
#
#  id               :integer          not null, primary key
#  consent_nr       :string(8)
#  consent_name     :string(100)
#  consent_abbrev   :string(50)
#  email_confirm_to :string(255)
#  created_at       :datetime
#  updated_at       :timestamp        not null
#

require 'test_helper'

class ConsentProtocolTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
