class UserStamper < ActionController::Caching::Sweeper
  observe SampleCharacteristic, Sample, ProcessedSample, MolecularAssay, LibSample, SeqLib, SampleStorageContainer,
          Histology, Pathology, StorageDevice, AlignmentRef, RunDir, MachineIncident, AttachedFile, AssignedBarcode,
          Item, Order

  def before_validation(model_obj)
    return unless current_user
    model_obj.send(:created_by=, current_user.id) if(model_obj.new_record? && model_obj.respond_to?(:created_by=))
    model_obj.send(:updated_by=, current_user.id) if(model_obj.changed? && model_obj.respond_to?(:updated_by=))
  end

  protected
  def current_user
    controller.send(:current_user) if(controller.respond_to?(:current_user))
  end
end