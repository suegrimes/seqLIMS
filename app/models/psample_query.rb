# == Schema Information
#
# Table name: psample_queries
#
#  mrn                 :string
#  patient_id          :string
#  barcode_key         :string
#  consent_protocol_id :integer
#  clinic_or_location  :string
#  sample_tissue       :string
#  sample_type         :string
#  tissue_preservation :string
#  pathology           :string
#  tumor_normal        :string
#  protocol_id         :string
#  extraction_type     :string
#  from_date           :date
#  to_date             :date
#

class PsampleQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :mrn,         :string
  column :patient_id,  :string
  column :barcode_key, :string
  column :consent_protocol_id, :integer
  column :clinic_or_location, :string
  column :sample_tissue, :string
  column :sample_type, :string
  column :tissue_preservation, :string
  column :pathology, :string
  column :tumor_normal, :string
  column :protocol_id, :string
  column :extraction_type, :string
  column :from_date,   :date
  column :to_date,     :date

  validates_format_of :patient_id, :with => /^\d+$/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  SCHAR_FLDS   = %w{patient_id consent_protocol_id clinic_or_location sample_tissue sample_type tissue_preservation pathology}
  SAMPLE_FLDS  = %w{tumor_normal}
  PSAMPLE_FLDS = %w{barcode_key protocol_id extraction_type} 
  ALL_FLDS     = SCHAR_FLDS | SAMPLE_FLDS | PSAMPLE_FLDS
end
