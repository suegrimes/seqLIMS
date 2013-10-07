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
  before_create :check_range
  before_save :range_start_chk
  
  def self.count_overlapping_range(rstart, rend)
    return self.where("start_barcode <= ? AND end_barcode >= ?", rend, rstart).count
    #return self.count(:conditions => ["start_barcode <= ? AND end_barcode >= ?", rend, rstart])
  end
  
protected
  def range_start_chk
    range_ok = true
    if end_barcode < start_barcode
      errors.add :end_barcode, "- cannot be less than start barcode"
      range_ok = false
    end
    return range_ok
  end

  def check_range
    range_ok = true
    if AssignedBarcode.count_overlapping_range(start_barcode, end_barcode) > 0
      errors.add :base, "Barcode range overlaps existing assigned range(s)"
      range_ok = false
    elsif Sample.count_samples_in_range(start_barcode, end_barcode) > 0
      errors.add :base, "Existing samples in LIMS in this range"
      range_ok = false
    end
    return range_ok
  end
end
