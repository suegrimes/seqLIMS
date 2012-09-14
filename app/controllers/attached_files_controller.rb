class AttachedFilesController < ApplicationController
  
  # GET /attached_files/1
  def show
    @attached_file = AttachedFile.find(params[:id])
    headers["Content-Type"] = @attached_file.document.content_type.to_s
    send_file(@attached_file.doc_fullpath) 
  end
 
  def get_params  
  end
  
  def new
    if params[:rec_type]
      @obj = source_rec(params[:rec_type], nil, params[:obj_id])
      
    elsif params[:sample] && !param_blank?(params[:sample][:barcode_key])
      @obj = source_rec('sample', params[:sample][:barcode_key])
      
    elsif params[:histology] && !param_blank?(params[:histology][:he_barcode_key])
      @obj = source_rec('histology', params[:histology][:he_barcode_key])
    
    elsif params[:processed_sample] && !param_blank?(params[:processed_sample][:barcode_key])
      @obj = source_rec('processed_sample', params[:processed_sample][:barcode_key])
      
    elsif params[:molecular_assay] && !param_blank?(params[:molecular_assay][:barcode_key])
      @obj = source_rec('molecular_assay', params[:molecular_assay][:barcode_key])
    
    elsif params[:seq_lib] && !param_blank?(params[:seq_lib][:barcode_key])
      @obj = source_rec('seq_lib', params[:seq_lib][:barcode_key])
      
    elsif params[:flow_cell] && !param_blank?(params[:flow_cell][:sequencing_key])
      @obj = source_rec('flow_cell', params[:flow_cell][:sequencing_key])
       
    else
      flash.now[:error] = "Please enter either relevant barcode, or sequencing run"
    end
    
    if flash.now[:error]
      #@lib_barcode    = params[:lib_barcode]
      #@sequencing_key = params[:sequencing_key]
      render :action => :get_params
      
    else
      render :action => :new
    end
  end
  
  def create
    @attached_file = AttachedFile.new(params[:attached_file])
    @attached_file.sampleproc = params[:obj_klass].constantize.find_by_id(params[:obj_id])
    
    if @attached_file.save
      flash[:notice] = 'Attached file successfully saved'
      redirect_to :controller => params[:obj_klass].underscore.pluralize, :action => :show, :id => params[:obj_id]
      #redirect_to :action => :new, :rec_type => params[:obj_klass].underscore, :obj_id => params[:obj_id]
    else
      flash.now[:error] = "Validation error - unable to save attached file"
      @obj = source_rec(params[:obj_klass].underscore, nil, params[:obj_id])
      render :action => :new
    end  
    
  end
  
  def destroy
    @attached_file = AttachedFile.find(params[:id])
    @file_name = @attached_file.basename_with_ext
    @file_path = @attached_file.doc_fullpath
    
    # delete file from file system
    File.delete(@file_path) if FileTest.exist?(@file_path)
    
    # delete file entry from SQL uploads table
    rec_type = @attached_file.sampleproc_type.underscore
    obj_id   = @attached_file.sampleproc_id
    @attached_file.destroy
    #redirect_to :action => 'new', :rec_type => rec_type, :obj_id => obj_id
    redirect_to :controller => rec_type.pluralize, :action => :show, :id => obj_id
  end

protected
  def source_rec(rec_type, rec_key, obj_id=nil)
    if obj_id
      obj = get_obj_with_id(rec_type, obj_id)
    else 
      obj = get_obj_with_key(rec_type, rec_key)
    end
    
    flash.now[:error] = "#{rec_type} record not found" if obj.nil?
    return obj
  end
  
  def get_obj_with_id(rec_type, obj_id)
    obj = case rec_type
          when 'sample' then Sample.getwith_attach(obj_id)
          when 'histology' then Histology.getwith_attach(obj_id)
          when 'pathology' then Pathology.getwith_attach(obj_id)
          when 'processed_sample' then ProcessedSample.getwith_attach(obj_id)
          when 'molecular_assay' then MolecularAssay.getwith_attach(obj_id)
          when 'seq_lib'   then SeqLib.getwith_attach(obj_id)
          when 'flow_cell' then FlowCell.getwith_attach(obj_id)
          else nil
    end
    return obj
  end
  
  def get_obj_with_key(rec_type, rec_key)
    case rec_type
      when 'sample'
        obj = Sample.find_by_barcode_key(rec_key, :include => :attached_files)
      when 'histology'
        obj = Histology.find_by_he_barcode_key(rec_key, :include => :attached_files)
      when 'processed_sample'
        obj = ProcessedSample.find_by_barcode_key(rec_key, :include => :attached_files)
      when 'molecular_assay'
        obj = MolecularAssay.find_by_barcode_key(rec_key, :include => :attached_files)
      when 'seq_lib'
        obj = SeqLib.find_by_barcode_key(rec_key, :include => :attached_files)
      when 'flow_cell'
        obj = FlowCell.find_by_sequencing_key(rec_key, :include => :attached_files)
      else
        obj = nil
      end
    return obj
  end

end