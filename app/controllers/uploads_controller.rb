class UploadsController < ApplicationController

  # GET /uploads
  def index
    @file_content ||= (params[:file_content] ||= 'seq_result')
    @uploads = Upload.where('file_content = ?', @file_content).order('created_at DESC').all

    if @uploads.nil?
      flash[:notice] = 'No existing uploaded files, please upload a new file'
      render :action => 'new'
    else
      render :action => 'index'
    end
  end
 
  # GET /uploads/1
  def show
    @upload = Upload.find(params[:id])
  end 
  
  # GET /uploads/new
  def new
    @upload = Upload.new
    @file_content = 'seq_result'
  end

  def create
    @upload = Upload.new(params[:upload])
    @file_content = params[:upload][:file_content]
    
    if @upload.save
      flash[:notice] = 'File successfully uploaded.'
      redirect_to :action => 'index', :file_content => @file_content
    else
      flash.now[:notice] = 'Error uploading file - please correct any errors listed below'
      render :action => 'new' 
    end
  end
  
  def show_files
    @upload_file = Upload.listfile(params[:id])
    @file_content = params[:file_content]
  end

  # DELETE /uploads/1
  def destroy
    @upload = Upload.find(params[:id])
    @file_name = @upload.file_name_no_dir
    @file_path = @upload.existing_file_path
    
    # delete file from file system
    File.delete(@file_path) if FileTest.exist?(@file_path)
    
    # delete file entry from SQL uploads table
    @upload.destroy
    redirect_to :action => 'index', :file_content => @upload.file_content
  end

  def loadtodb
    @file_content = params[:file_content]
    upload    = Upload.find(params[:id]) 
    @file_name = upload.file_name_no_dir
    @file_path = upload.existing_file_path
    rc = $rec_loaded = $rec_rejected = 0
    
    if !FileTest.file?(@file_path)
      display_msg(-1, @file_name, @file_content, 0)
      return
    end
    
    # execute appropriate model method, based on value of @filetype
    if @file_content == 'SeqResults'
      rc = AnalysisLane.loadresults(@file_path)
      display_msg(rc, @file_name, @file_content, 0)

    else
      flash.now[:notice] = "Invalid content type #{@content_type} for file load to database"
    end
    
    # update database load date/time 
    if $rec_loaded > 0 then
      upload.update_attribute(:loadtodb_at, Time.now)
    end 
  end
  
  def display_msg (rc, filename, filetype, plates_created)
    case rc
      when 0
        case filetype
          when 'Design'
            error_msg = ($rec_rejected > 0 ? ", #{$rec_rejected.to_s} duplicate oligos ignored" : " ")
            flash.now[:notice] = "Oligo design file: #{$rec_loaded.to_s} designs loaded#{error_msg}"
          when 'Synthesis'
            error_msg = ($rec_rejected > 0 ? ", #{$rec_rejected.to_s} duplicate wells ignored" : " ")
            flash.now[:notice] = "Synthesis: #{plates_created.to_s} oligo synthesis plates loaded#{error_msg}" 
          when 'BioMek'
            error_msg = ($rec_rejected > 0 ? ", #{$rec_rejected.to_s} errors" : " ")
            flash.now[:notice] = "BioMek: #{$rec_loaded.to_s} plate/wells loaded#{error_msg}"
          end
        when -1
          flash.now[:notice] = "ERROR - File: #{filename} does not exist, or is not a regular file"
        when -2
          flash.now[:notice] = "ERROR - File: #{filename} is not a valid CSV file"
        when -3
          flash.now[:notice] = "ERROR - File: #{filename} contains insufficient columns"
        when -4
          if filetype == 'BioMek'
              flash.now[:notice] = "ERROR - File: #{filename} contains one or more invalid source plates/wells"
          else
              flash.now[:notice] = "ERROR - File: #{filename} contains one or more invalid #{filetype} records"
          end
        when -5
          flash.now[:notice]     = "ERROR - File: #{filename} load unsuccessful - check file column format"
        when -6
          flash.now[:notice]     = "ERROR - File: #{filename} load unsuccessful - incorrect column headers"
        else
          flash.now[:notice]     = "ERROR - File: #{filename} load unsuccessful - return code #{rc}"
      end     
  end
  
  def help
    #redirect_to :controller=>'help', :action=>'uploadformat'
  end
  
end