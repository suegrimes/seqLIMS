# == Schema Information
#
# Table name: sample_characteristics
#
#  id                      :integer(4)      not null, primary key
#  patient_id              :integer(4)
#  collection_date         :date
#  clinic_or_location      :string(100)
#  consent_protocol_id     :integer(4)
#  consent_nr              :string(15)
#  gender                  :string(1)
#  ethnicity               :string(35)
#  race                    :string(70)
#  xxx_sample_type         :string(50)
#  xxx_sample_tissue       :string(50)
#  xxx_left_right          :string(1)
#  xxx_tissue_preservation :string(25)
#  pathology_id            :integer(4)
#  pathology               :string(50)
#  comments                :string(255)
#  updated_by              :string(50)
#  created_at              :datetime
#  updated_at              :datetime
#

class SampleCharacteristic < ActiveRecord::Base
  require 'ezcrypto'
  
  has_many :samples
  belongs_to :patient
  belongs_to :consent_protocol
  belongs_to :pathology
  
  validates_presence_of :collection_date, :if => Proc.new { |a| a.new_record? }
  validates_date :collection_date, :allow_blank => true
  validates_presence_of :consent_protocol_id, :clinic_or_location
  
  after_save :save_sample
  
  def before_create
    self.gender    = self.patient.gender
    self.ethnicity = self.patient.ethnicity
    self.race      = self.patient.race
  end
  
  def consent_descr
    (consent_protocol.nil? ? consent_nr : [consent_nr, consent_protocol.consent_abbrev].join('/'))
  end
  
  def self.find_with_samples(patient_id=nil)
    condition_array = (patient_id.nil? ? [] : ['sample_characteristics.patient_id = ?', patient_id])
    self.find(:all, :include => :samples, 
                    :order   => 'sample_characteristics.patient_id, samples.barcode_key',
                    :conditions => condition_array)
  end
  
  # This method intended to be replaced with 'find_and_group_with_conditions' below
  # Delete when new method is in place
#  def self.find_with_samples_and_conditions(condition_array=nil)
#    sample_characteristics = self.find(:all, :include => :samples, 
#                    :order   => 'sample_characteristics.patient_id, sample_characteristics.barcode_key',
#                    :conditions => condition_array)
#    return sample_characteristics.group_by {|samp_char| [samp_char.patient_id, samp_char.mrn]}
#  end
  
  def self.find_and_group_with_conditions(condition_array=nil)
    sample_characteristics = self.find(:all, :include => [:patient, :samples], 
                    :order   => 'sample_characteristics.patient_id, sample_characteristics.collection_date DESC',
                    :conditions => condition_array)
    return sample_characteristics.size, 
           sample_characteristics.group_by {|samp_char| [samp_char.patient_id, samp_char.patient.mrn]}
  end
  
  def new_sample_attributes=(sample_attributes)  
    sample_attributes.each do |attributes|
      attributes.merge!({:sample_date => collection_date})
      samples.build(attributes)
    end 
  end
  
  def existing_sample_attributes=(sample_attributes)
    samples.reject(&:new_record?).each do |sample|
      attributes = sample_attributes[sample.id.to_s]
      if attributes
        sample.attributes = attributes
      else
        samples.delete(sample)
      end
    end
  end
  
  def save_sample
    samples.each do |sample|
      sample.save(false)  
    end
  end

end
