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
#  plate_number        :string(25)
#  plate_coord         :string(4)
#  notes               :string(255)
#  updated_by          :integer(2)
#  created_at          :datetime
#  updated_at          :timestamp       not null
#

class MolecularAssay < ActiveRecord::Base
  
  #attr_accessible :owner, :preparation_date, :protocol_id, :notes
  
  belongs_to :protocol
  belongs_to :processed_sample
  has_many :assay_genes
  has_many :attached_files, :as => :sampleproc

  accepts_nested_attributes_for :assay_genes
  
  validates_presence_of :owner, :protocol_id, :volume, :concentration
  validates_presence_of :source_sample_name, :message => "must be in LIMS - please select from auto-fill list"
  validates_uniqueness_of :barcode_key, :message => "generated is not unique - contact system admin"
  validates_date :preparation_date
  validates_associated :processed_sample, :message => "- source DNA/RNA must be selected from auto-fill list"
  
  before_validation :derive_barcode
  after_validation :check_concentration

  def derive_barcode
    # Need to add the following logic here?:
    # - case where source sample is not in the processed sample table? (is this going to be allowable?)
    protocol_code = (self.protocol ? self.protocol.protocol_code : '?')
    if self.processed_sample_id
      self.barcode_key = MolecularAssay.next_assay_barcode(self.processed_sample_id, self.processed_sample.barcode_key, protocol_code)
    end
  end
  
  def check_concentration
    if self.processed_sample && !self.vol_from_source.nil?
      errors.add(:volume, "- insufficent source volume/concentration") if self.vol_from_source > self.processed_sample.final_vol 
    end
  end

  def source_sample_name
    return (self.processed_sample ? self.processed_sample.barcode_key : nil)
  end
  
  def source_sample_name=(barcode)
    #self.processed_sample = ProcessedSample.find(:first, :conditions => ["barcode_key = ?", barcode]) if !barcode.blank?
    self.processed_sample = ProcessedSample.where("barcode_key = ?", barcode).first if !barcode.blank?
  end
  
  def vol_from_source
    if !self.processed_sample 
      return nil
    elsif self.processed_sample.final_conc.nil?
      return 0
    else
      return (volume * concentration)/self.processed_sample.final_conc
    end
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
    #barcode_max  = self.maximum(:barcode_key, :conditions => ["processed_sample_id = ? AND barcode_key LIKE ?", source_id.to_i, barcode_mask])
    barcode_max = self.where("processed_sample_id = ? AND barcode_key LIKE ?", source_id.to_i, barcode_mask).maximum(:barcode_key)
    if barcode_max
      return barcode_max.succ  # Existing assay, so increment last 1-2 characters of max barcode string (eg. 3->4, or 09->10)
    else
      return [source_barcode, '.', protocol_char, '01'].join # No existing assays of this type, so add '01' suffix.  (eg. C01 if array-CGH)
    end
  end
  
  def self.getwith_attach(id)
    self.find(id, :include => :attached_files)
  end
  
  def self.find_for_query(condition_array=[])
    self.includes(:protocol, {:processed_sample => :sample}).where(sql_where(condition_array))
        .order('processed_samples.patient_id, processed_samples.barcode_key, molecular_assays.barcode_key').all
    #self.find(:all, :include => [:protocol, {:processed_sample => :sample}],
    #                :order => "processed_samples.patient_id, processed_samples.barcode_key, molecular_assays.barcode_key",
    #                :conditions => condition_array)
  end
end
