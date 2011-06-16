class AssignedBarcode < ActiveRecord::Base
  validates_numericality_of :start_barcode, :end_barcode, :only_integer => true
  validates_date :assign_date

  def self.count_overlapping_range(rstart, rend)
    return self.count(:conditions => ["start_barcode <= ? AND end_barcode >= ?", rend, rstart])
  end
  
protected
  def validate
    errors.add_to_base("Overlaps existing assigned range(s)") if AssignedBarcode.count_overlapping_range(start_barcode, end_barcode) > 0
    errors.add_to_base("Existing samples in LIMS in this range") if Sample.count_samples_in_range(start_barcode, end_barcode) > 0
    errors.add(:end_barcode, "- cannot be less than start barcode") if end_barcode < start_barcode 
  end
end
