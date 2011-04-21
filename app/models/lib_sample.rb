# == Schema Information
#
# Table name: lib_samples
#
#  id                  :integer(4)      not null, primary key
#  seq_lib_id          :integer(4)
#  processed_sample_id :integer(4)
#  sample_name         :string(50)
#  source_DNA          :string(50)
#  multiplex_type      :string(50)
#  index_tag           :string(2)
#  target_pool         :string(50)
#  enzyme_code         :string(50)
#  notes               :string(255)
#  updated_by          :integer(4)
#  created_at          :datetime
#  updated_at          :timestamp
#

class LibSample < ActiveRecord::Base
  
  belongs_to :molecular_assay
  belongs_to :seq_lib
  belongs_to :processed_sample
  
  validates_presence_of :sample_name
  validates_presence_of :multiplex_type, :if => Proc.new {|s| !s.seq_lib_id.nil? }
  
  def source_sample_name
    return source_DNA
  end
  
  def source_sample_name=(barcode)
    self.source_DNA = barcode
    self.processed_sample = ProcessedSample.find(:first, :conditions => ["barcode_key = ?", barcode]) if !barcode.blank?
  end
  
end
