# == Schema Information
#
# Table name: pathologies
#
#  id                       :integer(4)      not null, primary key
#  patient_id               :integer(4)      not null
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
#  updated_by               :string(10)
#  created_at               :datetime
#  updated_at               :timestamp
#

class Pathology < ActiveRecord::Base
  
  belongs_to :patient
  has_many :sample_characteristics, :dependent => :nullify
  
  validates_date :pathology_date, :allow_blank => true
  
  def tnm
    tval = (t_code.nil? ? ' ' : t_code)
    nval = (n_code.nil? ? ' ' : n_code)
    mval = (m_code.nil? ? ' ' : m_code)
    return ['T', tval, 'N', nval, 'M', mval].join
  end
  
end
