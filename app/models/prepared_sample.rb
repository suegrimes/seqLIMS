# == Schema Information
#
# Table name: prepared_samples
#
#  id                  :integer(4)      not null, primary key
#  processed_sample_id :integer(4)
#  barcode_key         :string(25)      default(""), not null
#  protocol_id         :integer(4)
#  preparation_date    :date
#  input_amt           :decimal(8, 3)
#  amt_used            :decimal(8, 3)
#  image_file          :string(100)
#  yield               :decimal(8, 3)
#  gc_content          :decimal(8, 3)
#  comments            :string(255)
#  updated_by          :integer(4)
#  created_at          :datetime
#  updated_at          :timestamp
#

# == Schema Information
#
# Table name: prepared_samples
#
class PreparedSample < ActiveRecord::Base
  belongs_to :processed_sample
  
  has_many :attached_files, :as => :sampleproc
  
  validates_date :preparation_date
  
  def self.find_all_incl_extracted
    self.find(:all, :include => :processed_sample,
                    :order => 'processed_samples.barcode_key')
  end
  
  def self.next_preparation_barcode(xsample_id, xsample_barcode)
    barcode_mask = [xsample_barcode, '.%'].join
    barcode_max  = self.maximum(:barcode_key, :conditions => ["processed_sample_id = ? AND barcode_key LIKE ?", xsample_id.to_i, barcode_mask])
    if barcode_max
      return barcode_max.succ  # Existing prepared sample, so increment last 1-2 characters of max barcode string (eg. 3->4, or 09->10)
    else
      return [xsample_barcode, '.M01'].join # No existing prepared samples for this extraction, so add 'M01' suffix. 
    end
  end
  
end
