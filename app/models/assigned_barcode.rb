# == Schema Information
#
# Table name: assigned_barcodes
#
#  id            :integer(4)      not null, primary key
#  assign_date   :date
#  group_name    :string(30)
#  owner_name    :string(25)
#  sample_type   :string(25)
#  start_barcode :integer(3)      not null
#  end_barcode   :integer(3)      not null
#  created_at    :datetime
#  updated_by    :integer(4)
#

class AssignedBarcode < ActiveRecord::Base
  validates_numericality_of :start_barcode, :end_barcode, :only_integer => true
  validates_date :assign_date

  validate_on_create :check_range
  
  def self.count_overlapping_range(rstart, rend)
    return self.count(:conditions => ["start_barcode <= ? AND end_barcode >= ?", rend, rstart])
  end
  
protected
  def validate
    errors.add(:end_barcode, "- cannot be less than start barcode") if end_barcode < start_barcode 
  end

  def check_range
    errors.add_to_base("Overlaps existing assigned range(s)") if AssignedBarcode.count_overlapping_range(start_barcode, end_barcode) > 0
    errors.add_to_base("Existing samples in LIMS in this range") if Sample.count_samples_in_range(start_barcode, end_barcode) > 0   
  end
end
