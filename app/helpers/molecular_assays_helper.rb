module MolecularAssaysHelper
  def sample_vol(molecular_assay)
    return number_with_precision(molecular_assay.vol_from_source, :precision => 2)
  end
  
  def buffer_vol(molecular_assay)
    return number_with_precision(molecular_assay.volume - molecular_assay.vol_from_source, :precision => 2)
  end
end