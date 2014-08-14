# == Schema Information
#
# Table name: adapters

class Adapter < ActiveRecord::Base
  has_many :index_tags

  def self.splex_adapters
    return ["S_SR", "S_PE"]
  end

  def self.mplex_adapters
    adapters = self.select(:runtype_adapter).pluck(:runtype_adapter)
    return adapters.unshift("M_SR")
  end
end
