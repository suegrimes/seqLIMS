# == Schema Information
#
# Table name: molecular_assays
#
#  id                  :integer(4)      not null, primary key
#  barcode_key         :string(20)
#  assay_descr         :string(50)      default(""), not null
#  protocol_id         :integer(4)
#  owner               :string(25)
#  preparation_date    :date
#  notebook_ref        :string(50)
#  notes               :string(255)
#  quantitation_method :string(20)
#  updated_by          :string(50)
#  created_at          :datetime
#  updated_at          :timestamp       not null
#

class MolecularAssay < ActiveRecord::Base
  
  has_many :lib_samples  
  accepts_nested_attributes_for :lib_samples
  
  validates_presence_of :barcode_key, :source_DNA, :owner
  validates_uniqueness_of :barcode_key, :message => "is not unique"
  validates_format_of :barcode_key, :with => /^M\d+$/, :message => "must start with 'M', followed by digits"
  validates_date :preparation_date
  
  def owner_abbrev
    if owner.nil? || owner.length < 11
      owner1 = owner
    else
      first_and_last = owner.split(' ')
      owner1 = [first_and_last[0], first_and_last[1][0,1]].join(' ')
    end
    return owner1
  end
  
end
