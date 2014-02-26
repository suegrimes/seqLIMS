# == Schema Information
#
# Table name: lib_samples
#
#  id                  :integer          not null, primary key
#  seq_lib_id          :integer
#  splex_lib_id        :integer
#  splex_lib_barcode   :string(20)
#  processed_sample_id :integer
#  sample_name         :string(50)
#  source_DNA          :string(50)
#  runtype_adapter     :string(50)
#  index_tag           :integer
#  enzyme_code         :string(50)
#  notes               :string(255)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :timestamp
#

class LibSample < ActiveRecord::Base
  
  belongs_to :seq_lib
  belongs_to :splex_lib, :class_name => 'SeqLib', :foreign_key => :splex_lib_id
  belongs_to :processed_sample
  
  validates_presence_of :sample_name
  validates_presence_of :runtype_adapter, :if => Proc.new {|s| !s.seq_lib_id.nil? }
  validates_presence_of :index_tag, :if => Proc.new{|s| s.runtype_adapter[0,1] == 'M'}, :message => 'must be supplied for multiplex adapters'
  #validates_numericality_of :index_tag, :only_integer => true, :allow_blank => true, :message => 'must be an integer'
  #validates_format_of :index_tag, :with => /^\d+$/, :allow_blank => true, :message => "must be an integer"
  #validates_inclusion_of :index_tag, :in => 1..12, :if => Proc.new{|s| s.runtype_adapter[0,1] == 'M'},
  #                       :message => 'must be between 1 and 12'
   
  def validate
    max_tags = (runtype_adapter == 'M_PE_Illumina' ? SeqLib::MILLUMINA_SAMPLES : SeqLib::MULTIPLEX_SAMPLES)
    if runtype_adapter == 'M_PE' && !index_tag.nil?
      errors.add(:index_tag, "must be in range 1 - #{max_tags} for #{runtype_adapter} adapter") if (index_tag < 1 || index_tag > max_tags)
    end  
  end
  
  def patient_id
    (!processed_sample.nil? ? processed_sample.patient_id : nil)
  end

  def tag_sequence
    return (index_tag.nil? ? '' : IndexTag.find_or_blank(runtype_adapter, index_tag))
  end
  
  def source_sample_name
    return source_DNA
  end
  
  def source_sample_name=(barcode)
    self.source_DNA = barcode
    self.processed_sample = ProcessedSample.where("barcode_key = ?", barcode).first if !barcode.blank?
  end
  
  def singleplex_lib
    return splex_lib_barcode
  end
  
  def singleplex_lib=(lib_barcode)
    #self.splex_lib_barcode = lib_barcode
    self.splex_lib = nil if lib_barcode.blank?
    
    if !lib_barcode.blank?
      #slib = SeqLib.find(:first, :include => :lib_samples, :conditions => ["library_type = 'S' AND barcode_key = ?", lib_barcode])
      slib = SeqLib.includes(:lib_samples).where("library_type = 'S' AND barcode_key = ?", lib_barcode).first
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
  
  def self.upd_mplex_sample_fields(seq_lib)
    lsample_attrs = {}
    
    lib_samples = self.find_all_by_splex_lib_id(seq_lib.id)  # Find any multiplex libraries which include this single lib
    if lib_samples
      # Set up those attributes that come from lib_samples table of singleplex lib
      # Should always be one and only one lib_sample for a singleplex lib; but test for existence of lib_samples just in case
      lsample_attrs = {:index_tag           => seq_lib.lib_samples[0].index_tag,
                       :sample_name         => seq_lib.lib_samples[0].sample_name,
                       :source_DNA          => seq_lib.lib_samples[0].source_DNA,
                       :processed_sample_id => seq_lib.lib_samples[0].processed_sample_id} if seq_lib.lib_samples
      # Set up those attributes that come from seq_libs table for singleplex lib
      lsample_attrs.merge!(:splex_lib_barcode => seq_lib.barcode_key,
                           :runtype_adapter   => seq_lib.runtype_adapter)
      # Update attributes for all multiplex samples which reference this singleplex lib
      self.upd_multi_lib_samples(lib_samples, lsample_attrs)
    end
  end
  
  def self.upd_multi_lib_samples(lib_samples, attrs)
    # Set up arrays of ids, and of attribute values, for SQL update of multiple lib_samples
    lib_sample_ids   = lib_samples.collect(&:id) if lib_samples
    if lib_sample_ids
      lib_sample_attrs = []
      lib_sample_ids.each_with_index {|lib_sample_id, i| lib_sample_attrs[i] = attrs} 
      self.update(lib_sample_ids, lib_sample_attrs)
    end
  end
end
