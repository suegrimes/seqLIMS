# == Schema Information
#
# Table name: histology_queries
#
#  consent_protocol_id  :integer
#  clinic_or_location   :string
#  tissue_preservation  :string
#  from_date    :date
#  to_date      :date
#

class HistologyQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end

  column :mrn,         :string
  column :patient_id,  :string
  column :barcode_string, :string
  column :alt_identifier, :string
  column :consent_protocol_id, :string
  column :clinic_or_location,  :string
  column :tissue_preservation, :string
  column :from_date, :date
  column :to_date,   :date

  validates_date :to_date, :from_date, :allow_blank => true

  SAMPLE_FLDS = %w{alt_identifier tissue_preservation}
  SCHAR_FLDS = %w{patient_id consent_protocol_id clinic_or_location}
  ALL_FLDS    = SCHAR_FLDS | SAMPLE_FLDS
end
