class AssignedBarcode < ActiveRecord::Base
  validates_numericality_of :start_barcode, :end_barcode, :only_integer => true
  validates_date :assign_date
  
protected
  def validate
    errors.add(:end_barcode, "- cannot be less than start barcode") if end_barcode < start_barcode 
    errors.add_to_base("Existing samples in LIMS in this range") if Sample.count_samples_in_range(start_barcode, end_barcode) > 0
  end
end
