module LimsCommon
  ###############################################################################################
  # build_params_from_obj:                                                                      #
  # Build parameter hash, using values of provided fields from provided object                  # 
  # Use this, for example, to copy values of specific fields from source sample to associated   #
  #   dissection(s)                                                                             #
  ###############################################################################################
  def build_params_from_obj(obj, flds)
    params_hash = {}
    flds.each do |fld|
      params_hash.merge!(fld.to_sym => obj.send(fld))
    end
    return params_hash
  end
  
end