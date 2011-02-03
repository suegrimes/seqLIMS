# == Schema Information
#
# Table name: processed_samples
#
#  id                  :integer(4)      not null, primary key
#  sample_id           :integer(4)
#  patient_id          :integer(4)
#  protocol_id         :integer(4)
#  extraction_type     :string(25)
#  processing_date     :date
#  input_uom           :string(25)
#  input_amount        :decimal(11, 3)
#  barcode_key         :string(25)
#  old_barcode         :string(25)
#  support             :string(25)
#  elution_buffer      :string(25)
#  vial                :string(10)
#  final_vol           :decimal(11, 3)
#  final_conc          :decimal(11, 3)
#  final_a260_a280     :decimal(11, 3)
#  final_rin_nr        :decimal(4, 1)
#  psample_remaining   :string(2)
#  storage_location_id :integer(4)
#  storage_shelf       :string(10)
#  storage_boxbin      :string(25)
#  comments            :string(255)
#  updated_by          :string(50)
#  created_at          :datetime
#  updated_at          :timestamp       not null
#

class ProcessedSample < ActiveRecord::Base
  belongs_to :sample
  belongs_to :patient
  belongs_to :storage_location
  
  validates_date :processing_date
  
  def before_create
    self.barcode_key = ProcessedSample.next_extraction_barcode(self.sample_id, self.sample.barcode_key, self.extr_type_char)
  end
  
  def initial_amt_ug
    (initial_vol * initial_conc / 1000) if (!initial_vol.nil? && !initial_conc.nil?)
  end
  
  def final_amt_ug
    (final_vol * final_conc / 1000) if (!final_vol.nil? && !final_conc.nil?)
  end
  
  def extr_type_char
    echar = case extraction_type
      when /(.*)DNA(.*)/     then 'D'
      when /(.*)RNA(.*)/     then 'R'
      when /(.*)Nucleic(.*)/ then 'N'
      when /(.*)Protein(.*)/ then 'P'
      else '?'
    end
    return echar
  end
  
  def self.find_all_incl_sample
    self.find(:all, :include => [:sample, :storage_location],
                    :order => 'samples.patient_id, samples.barcode_key')
  end
  
  def self.find_for_query(condition_array=nil)
    self.find(:all, :include => [{:sample => :sample_characteristic}, :storage_location],
                    :order => "samples.patient_id, samples.barcode_key, processed_samples.barcode_key",
                    :conditions => condition_array)
  end
  
  def self.find_for_export(psample_ids)
    self.find(:all, :include => [:sample, :storage_location],
              :conditions => ["processed_samples.id IN (?)", psample_ids],
              :order => "samples.patient_id, samples.barcode_key, processed_samples.barcode_key")
  end
  
  def self.next_extraction_barcode(source_id, source_barcode, extraction_char)
    barcode_mask = [source_barcode, '.', extraction_char, '%'].join
    barcode_max  = self.maximum(:barcode_key, :conditions => ["sample_id = ? AND barcode_key LIKE ?", source_id.to_i, barcode_mask])
    if barcode_max
      return barcode_max.succ  # Existing extraction, so increment last 1-2 characters of max barcode string (eg. 3->4, or 09->10)
    else
      return [source_barcode, '.', extraction_char, '01'].join # No existing extractions of this type, so add '01' suffix.  (eg. D01 if DNA extraction)
    end
  end
  
end
