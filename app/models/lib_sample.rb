# == Schema Information
#
# Table name: lib_samples
#
#  id                  :integer(4)      not null, primary key
#  seq_lib_id          :integer(4)
#  splex_lib_id        :integer(4)
#  splex_lib_barcode   :string(20)
#  processed_sample_id :integer(4)
#  sample_name         :string(50)
#  source_DNA          :string(50)
#  runtype_adapter     :string(50)
#  index_tags          :string(20)
#  enzyme_code         :string(50)
#  notes               :string(255)
#  updated_by          :integer(4)
#  created_at          :datetime
#  updated_at          :timestamp
#

class LibSample < ActiveRecord::Base
  
  belongs_to :seq_lib
  belongs_to :splex_lib, :class_name => 'SeqLib', :foreign_key => :splex_lib_id
  belongs_to :processed_sample
  
  validates_presence_of :sample_name
  validates_presence_of :runtype_adapter, :if => Proc.new {|s| !s.seq_lib_id.nil? }
  
  def source_sample_name
    return source_DNA
  end
  
  def source_sample_name=(barcode)
    self.source_DNA = barcode
    self.processed_sample = ProcessedSample.find(:first, :conditions => ["barcode_key = ?", barcode]) if !barcode.blank?
  end
  
  def singleplex_lib
    return splex_lib_barcode
  end
  
  def singleplex_lib=(lib_barcode)
    self.splex_lib_barcode = lib_barcode
    self.splex_lib = nil if lib_barcode.blank?
    
    if !lib_barcode.blank?
      slib = SeqLib.find(:first, :include => :lib_samples, :conditions => ["barcode_key = ?", lib_barcode]) 
      if slib && slib.lib_samples
        ssample = slib.lib_samples[0]
        self.splex_lib = slib
        self.splex_lib_barcode = slib.barcode_key
        self.processed_sample_id = ssample.processed_sample_id
        self.sample_name = ssample.sample_name
        self.source_DNA  = ssample.source_DNA
        self.runtype_adapter = ssample.runtype_adapter
        self.index_tag = ssample.index_tag
        self.enzyme_code = ssample.enzyme_code
      end
    end
  end
end
