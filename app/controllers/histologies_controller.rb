class HistologiesController < ApplicationController
  load_and_authorize_resource
  
  before_filter :dropdowns, :only => [:new, :edit, :edit_by_barcode]
  
  def new_params
    authorize! :create, Histology
    render :action => 'new_params'
  end
  
  def new
    if param_blank?(params[:barcode_key])
      flash.now[:error] = 'Error - sample barcode cannot be blank'
      render :action => 'new_params'
      
    else
      @sample = Sample.includes(:sample_characteristic => :pathology).where('barcode_key = ?', params[:barcode_key]).first
      if @sample && @sample.histology.nil?
        # Determine next increment number for barcode suffix (only use this if allowing >1 H&E slide per sample)
        #he_barcode = Histology.next_he_barcode(@sample.id, @sample.barcode_key)
        @histology = Histology.new(:sample_id => @sample.id,
                                   :he_barcode_key => Histology.new_he_barcode(@sample.barcode_key))
        #@histology = @sample.build_histology 
        render :action => 'new'
        
      elsif @sample  #Have sample, and histology is not nil
        #flash[:notice] = 'H&E slide exists for sample barcode: ' + params[:barcode_key] 
        redirect_to :action => 'edit', :id => @sample.histology.id
        
      else
        flash.now[:error] = 'Error - sample barcode ' + params[:barcode_key] + ' not found'
        render :action => 'new_params'
      end
    end
  end
  
  def create
    @histology = Histology.new(params[:histology])

    if @histology.save
      flash[:notice] = 'H&E slide was successfully created.'
      redirect_to(@histology)
    else
      prepare_for_render_new(@histology.sample_id)
      render :action => "new" 
    end
  end
  
  def edit
  end

  def edit_by_barcode
    @histology = Histology.find_by_he_barcode_key(params[:barcode_key],
                                                  :include => {:sample => [{:sample_characteristic => :pathology}, :patient]})
    if @histology
      render :action => :edit
    else
      flash[:error] = 'No entry found for H&E barcode: ' + params[:barcode_key]
      redirect_to :action => :new_params
    end
  end
  
  def update
    @histology = Histology.find(params[:id])
    
    if @histology.update_attributes(params[:histology])
      flash[:notice] = 'H&E slide was successfully updated'
      redirect_to(@histology)
    #render :action => 'debug'
    else
      prepare_for_render_new(@histology.sample_id)
      render :action => 'edit'
    end
  end

  def show
    @histology = Histology.includes(:sample => [{:sample_characteristic => :pathology}, :patient]).find(params[:id])
    render :action => :show
  end

  def index
  end

# DELETE /patients/1
  def destroy
    @histology = Histology.find(params[:id])
    flash[:notice] = "H&E slide #{@histology.he_barcode_key} deleted"
    @histology.destroy  
    redirect_to :controller => :samples, :action => :edit_params
  end

  def auto_complete_for_barcode_key
    @histologies = Histology.where('he_barcode_key LIKE ?', params[:search]+'%').all
    render :inline => "<%= auto_complete_result(@histologies, 'he_barcode_key') %>"
  end

## Protected and private methods ##
protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Pathology'], Cgroup::CGROUPS['Histology']])
    @histopathology     = category_filter(@category_dropdowns, 'pathology')
    @inflam_type        = category_filter(@category_dropdowns, 'inflammation type')
    @inflam_infiltr     = category_filter(@category_dropdowns, 'inflammation infiltration')
  end
  
  def prepare_for_render_new(sample_id)
    dropdowns
    @sample = Sample.includes(:sample_characteristic => :pathology).find(sample_id)
  end

end