# == Schema Information
#
# Table name: molecular_assays
#
#  id                  :integer(4)      not null, primary key
#  barcode_key         :string(20)      default(""), not null
#  processed_sample_id :integer(4)
#  protocol_id         :integer(4)
#  owner               :string(25)
#  preparation_date    :date
#  volume              :integer(2)
#  concentration       :decimal(8, 3)
#  notes               :string(255)
#  updated_by          :string(50)
#  created_at          :datetime
#  updated_at          :timestamp       not null
#

class MolecularAssay < ActiveRecord::Base
  belongs_to :protocol
  belongs_to :processed_sample
  has_many :attached_files, :as => :sampleproc
  
  validates_presence_of :barcode_key, :owner, :protocol_id, :processed_sample_id
  validates_uniqueness_of :barcode_key, :message => "is not unique"
  #validates_format_of :barcode_key, :with => /^M\d+$/, :message => "must start with 'M', followed by digits"
  validates_date :preparation_date
  
  def before_validation
    # Need to add the following logic here?:
    # - case where source sample is not in the processed sample table? (is this going to be allowable?)
    protocol_code = (self.protocol ? self.protocol.protocol_code : '?')
    self.barcode_key = MolecularAssay.next_assay_barcode(self.processed_sample_id, self.processed_sample.barcode_key, protocol_code)
  end
   
  def source_sample_name
    return (self.processed_sample ? self.processed_sample.barcode_key : nil)
  end
  
  def source_sample_name=(barcode)
    self.processed_sample = ProcessedSample.find(:first, :conditions => ["barcode_key = ?", barcode]) if !barcode.blank?
  end
  
  def protocol_name
    return (self.protocol ? self.protocol.protocol_name : '')
  end
  
  def owner_abbrev
    if owner.nil? || owner.length < 11
      owner1 = owner
    else
      first_and_last = owner.split(' ')
      owner1 = [first_and_last[0], first_and_last[1][0,1]].join(' ')
    end
    return owner1
  end
  
  def self.next_assay_barcode(source_id, source_barcode, protocol_char)
    barcode_mask = [source_barcode, '.', protocol_char, '%'].join
    barcode_max  = self.maximum(:barcode_key, :conditions => ["processed_sample_id = ? AND barcode_key LIKE ?", source_id.to_i, barcode_mask])
    if barcode_max
      return barcode_max.succ  # Existing assay, so increment last 1-2 characters of max barcode string (eg. 3->4, or 09->10)
    else
      return [source_barcode, '.', protocol_char, '01'].join # No existing assays of this type, so add '01' suffix.  (eg. C01 if array-CGH)
    end
  end
  
end
