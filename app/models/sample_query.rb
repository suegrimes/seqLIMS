# == Schema Information
#
# Table name: sample_queries
#
#  mrn                 :string
#  patient_id          :string
#  barcode_key         :string
#  gender              :string
#  consent_protocol_id :integer
#  clinic_or_location  :string
#  race                :string
#  sample_tissue       :string
#  sample_type         :string
#  tissue_preservation :string
#  tumor_normal        :string
#  date_filter         :string
#  from_date           :date
#  to_date             :date
#

class SampleQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :mrn,         :string
  column :patient_id,  :string
  column :barcode_key, :string
  column :gender,      :string
  column :consent_protocol_id, :integer
  column :clinic_or_location, :string
  column :race, :string
  column :sample_tissue, :string
  column :sample_type, :string
  column :tissue_preservation, :string
  column :tumor_normal, :string
  column :date_filter, :string
  column :from_date,   :date
  column :to_date,     :date

  validates_format_of :patient_id, :with => /^\d+$/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  SCHAR_FLDS = %w{patient_id gender consent_protocol_id clinic_or_location race }
  SAMPLE_FLDS = %w{barcode_key tumor_normal sample_tissue sample_type tissue_preservation}
  ALL_FLDS    = SCHAR_FLDS | SAMPLE_FLDS
end
