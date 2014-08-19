# == Schema Information
#
# Table name: adapters

class Adapter < ActiveRecord::Base
  has_many :index_tags

  def self.default_adapter
    return self.where('runtype_adapter = "M_PE"')
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
