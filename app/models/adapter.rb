# == Schema Information
#
# Table name: adapters

class Adapter < ActiveRecord::Base
  has_many :index_tags
  accepts_nested_attributes_for :index_tags, :reject_if => proc {|attrs| attrs[:tag_sequence].blank?},
                                :allow_destroy => true
  default_scope { where("adapters.runtype_adapter <> ?", "Multiple") }

  def self.default_adapter
    return self.where('runtype_adapter = "M_PE"').first
  end

  def self.splex_adapters
    return self.where('mplex_splex = "S"')
  end

  def self.mplex_adapters
    return self.where('mplex_splex = "M"')
    #return adapters.unshift("M_SR")
  end

  def self.populate_dropdown
    return self.all
  end
end
