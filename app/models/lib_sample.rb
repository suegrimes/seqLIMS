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
  belongs_to :mplex_lib, :class_name => 'SeqLib', :foreign_key => :mplex_lib_id
  belongs_to :processed_sample
  
  validates_presence_of :sample_name
  validates_presence_of :runtype_adapter, :if => Proc.new {|s| !s.seq_lib_id.nil? }
  validates_presence_of :index_tag, :if => Proc.new{|s| s.runtype_adapter[0,1] == 'M'}, :message => 'must be supplied for multiplex adapters'
  validates_numericality_of :index_tag, :only_integer => true, :allow_blank => true, :message => 'must be an integer'
  #validates_format_of :index_tag, :with => /^\d+$/, :allow_blank => true, :message => "must be an integer"
  
  def source_sample_name
    return source_DNA
  end
  
  def source_sample_name=(barcode)
    self.source_DNA = barcode
    self.processed_sample = ProcessedSample.find(:first, :conditions => ["barcode_key = ?", barcode]) if !barcode.blank?
  end
  
end
