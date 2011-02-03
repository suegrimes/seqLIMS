class ResultFilesController < ApplicationController
  RFILE_DIR = "#{RAILS_ROOT}/public"

  def index
    @rfile_dir    = RFILE_DIR
    @result_files = ResultFile.find(:all, :include => :analysis)
  end

  def new
    params[:analysis_id] ||= []
    @result_files = ResultFile.new(:analysis_id => params[:analysis_id])
    @analyses    = Analysis.find(:all)
  end

  def show
    @result_file = ResultFile.find params[:id]
    send_file("#{RFILE_DIR}#{@result_file.rfile}")
  end

  def create
    @result_file = ResultFile.new(params[:result_files])
    @result_file.save!
    redirect_to :action => 'index'
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end
  
  def destroy
    @result_file = ResultFile.find(params[:id])  
    # delete file from file system
    @rfile_path = "#{RFILE_DIR}#{@result_file.rfile}"
    File.delete(@rfile_path) if File.exist?(@rfile_path)
    # delete file entry from SQL result_files table
    @result_file.destroy

    redirect_to :action => 'index'
  end
end