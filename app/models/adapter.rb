# == Schema Information
#
# Table name: adapters
#
#  id              :integer          not null, primary key
#  runtype_adapter :string(25)
#  mplex_splex     :string(1)
#  multi_indices   :string(1)
#  index1_prefix   :string(2)
#  index2_prefix   :string(2)
#  tag_prefix      :string(2)
#  tag_suffix      :string(2)
#  tag_length      :integer
#  updated_at      :timestamp
#

class Adapter < ActiveRecord::Base
  has_many :index_tags
  accepts_nested_attributes_for :index_tags, :reject_if => proc {|attrs| attrs[:tag_sequence].blank?},
                                :allow_destroy => true
  #default_scope { where("adapters.runtype_adapter <> ?", "Multiple") }

  def self.default_adapter
    return self.where('runtype_adapter LIKE "M_%"').first
  end

  def self.splex_adapters
    return self.where('mplex_splex = "S"')
  end

  def self.mplex_adapters
    return self.where('mplex_splex = "M"')
  end

  def self.populate_dropdown
    return self.all
  end
end
