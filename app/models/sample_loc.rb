# == Schema Information
#
# Table name: samples
#
#  id                       :integer          not null, primary key
#  patient_id               :integer
#  sample_characteristic_id :integer
#  source_sample_id         :integer
#  source_barcode_key       :string(20)
#  barcode_key              :string(20)       not null
#  alt_identifier           :string(20)
#  sample_date              :date
#  sample_type              :string(50)
#  sample_tissue            :string(50)
#  left_right               :string(1)
#  tissue_preservation      :string(25)
#  tumor_normal             :string(25)
#  sample_container         :string(20)
#  vial_type                :string(30)
#  amount_initial           :decimal(10, 3)   default(0.0)
#  amount_rem               :decimal(10, 3)   default(0.0)
#  amount_uom               :string(20)
#  sample_remaining         :string(2)
#  storage_location_id      :integer
#  storage_shelf            :string(10)
#  storage_boxbin           :string(25)
#  comments                 :string(1024)
#  updated_by               :integer
#  created_at               :datetime
#  updated_at               :timestamp        not null
#

class SampleLoc < Sample
  has_many   :sample_storage_containers, :as => :stored_sample
  accepts_nested_attributes_for :sample_storage_containers, :allow_destroy => true

  def room_and_freezer
    (sample_storage_containers ? sample_storage_containers.map{|sc| sc.room_and_freezer}.uniq.join(',') : '')
  end
  
  def container_and_position
    (sample_storage_containers ? sample_storage_containers.map{|sc| sc.container_and_position}.join(',') : '')
  end

  def self.find_for_storage_query(condition_array)
    self.includes(:patient, :sample_characteristic, :sample_storage_containers, {:processed_samples => :sample_storage_container})
    .where(sql_where(condition_array)).order('samples.patient_id, samples.barcode_key, processed_samples.barcode_key').all
  end

  def self.find_for_export(sample_ids)
    self.find_for_storage_query(["samples.id IN (?)", sample_ids])
  end

end
