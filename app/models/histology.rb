# == Schema Information
#
# Table name: histologies
#
#  id                        :integer(4)      not null, primary key
#  sample_id                 :integer(4)
#  he_barcode_key            :string(20)      default(""), not null
#  he_date                   :date
#  histopathology            :string(25)
#  he_classification         :string(50)
#  pathologist               :string(50)
#  tumor_cell_content        :decimal(7, 3)
#  inflammation_type         :string(25)
#  inflammation_infiltration :string(25)
#  comments                  :string(255)
#  updated_by                :integer(2)
#  created_at                :datetime
#  updated_at                :timestamp
#

class Histology < ActiveRecord::Base
  
  belongs_to :sample
  has_many :attached_files, :as => :sampleproc
  
  validates_date :he_date
  validates_presence_of :pathologist

  def self.getwith_attach(id)
    self.includes(:attached_files).find(id)
  end
  
  def self.new_he_barcode(sample_barcode)
    return sample_barcode + '.H1'
  end

#  def self.next_he_barcode(sample_id, sample_barcode)
#    barcode_max = self.maximum(:he_barcode_key, :conditions => ["sample_id = ? AND he_barcode_key LIKE ?", sample_id.to_i, sample_barcode + '%'])
#    if barcode_max
#      return barcode_max.succ   # Increment last 1-2 characters of string (eg H02 -> H03, or H09 -> H10)
#    else
#      return sample_barcode + '.H01' # No existing dissections, so use 'H01' suffix
#    end  
#  end
  
end
