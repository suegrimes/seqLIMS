class UserStamper < ActionController::Caching::Sweeper
  observe SampleCharacteristic, Sample, ProcessedSample, MolecularAssay, LibSample, SeqLib, SampleStorageContainer,
          Histology, Pathology, StorageDevice, AlignmentRef, RunDir, MachineIncident, AttachedFile, AssignedBarcode,
          Item, Order

  def before_validation(record)
    return unless current_user
    record.send(:created_by=, current_user.id) if(record.new_record? && record.respond_to?(:created_by=))
    record.send(:updated_by=, current_user.id) if(record.changed? && record.respond_to?(:updated_by=))
  end

  private

  def current_user
    controller.send(:current_user) if(controller.respond_to?(:current_user))
  end
end