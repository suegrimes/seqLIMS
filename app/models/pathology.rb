# == Schema Information
#
# Table name: pathologies
#
#  id                       :integer          not null, primary key
#  patient_id               :integer          not null
#  collection_date          :date
#  pathology_date           :date
#  pathologist              :string(50)
#  general_pathology        :string(25)
#  pathology_classification :string(100)
#  tumor_stage              :string(2)
#  xrt_flag                 :string(2)
#  t_code                   :string(2)
#  n_code                   :string(2)
#  m_code                   :string(2)
#  comments                 :string(255)
#  updated_by               :integer
#  created_at               :datetime
#  updated_at               :timestamp
#

class Pathology < ActiveRecord::Base
  
  belongs_to :patient
  has_many :sample_characteristics, :dependent => :nullify
  has_many :attached_files, :as => :sampleproc
  
  validates_date :pathology_date, :allow_blank => true
  
  def tnm
    tval = (t_code.nil? ? ' ' : t_code)
    nval = (n_code.nil? ? ' ' : n_code)
    mval = (m_code.nil? ? ' ' : m_code)
    return ['T', tval, 'N', nval, 'M', mval].join
  end
  
   def self.getwith_attach(id)
    self.includes(:attached_files).find(id)
  end
  
end
