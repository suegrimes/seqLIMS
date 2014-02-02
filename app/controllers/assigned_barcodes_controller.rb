class AssignedBarcodesController < ApplicationController
 
  # GET /assigned_barcodes
  def index
    @assigned_barcodes = AssignedBarcode.order(:start_barcode).all
    @assigned_ranges = assigned_contigs(@assigned_barcodes)
    @free_ranges     = free_contigs(@assigned_ranges)
  end
  
  def check_barcodes
    @range_start = params[:start]
    @range_end   = params[:end]
    @samples = Sample.find_in_barcode_range(@range_start, @range_end)

    if params[:rtype] == 'available'
      render :action => 'check_available'
    else
      render :action => 'list_assigned'
    end   
  end
  
  # GET /assigned_barcodes/1
  def show
    @assigned_barcode = AssignedBarcode.find(params[:id])
  end

  # GET /assigned_barcodes/new
  def new
    @assigned_barcode = AssignedBarcode.new(:assign_date => Date.today,
                                            :start_barcode => params[:start], 
                                            :end_barcode => params[:end])
  end

  # GET /assigned_barcodes/1/edit
  def edit
    @assigned_barcode = AssignedBarcode.find(params[:id])
  end

  # POST /assigned_barcodes
  def create
    @assigned_barcode = AssignedBarcode.new(params[:assigned_barcode])

    if @assigned_barcode.save
      flash[:notice] = 'Assigned barcode range was successfully created.'
      redirect_to(assigned_barcodes_url)
    else
      render :action => "new" 
    end
  end

  # PUT /assigned_barcodes/1
  def update
    @assigned_barcode = AssignedBarcode.find(params[:id])

    if @assigned_barcode.update_attributes(params[:assigned_barcode])
      flash[:notice] = 'Assigned barcode range was successfully updated.'
      redirect_to(assigned_barcodes_url)
    else
      render :action => "edit" 
    end
  end

  # DELETE /assigned_barcodes/1
  def destroy
    @assigned_barcode = AssignedBarcode.find(params[:id])
    @assigned_barcode.destroy
    redirect_to(assigned_barcodes_url) 
  end
  
protected
  def assigned_contigs(assigned_barcodes)
    contigs = []
    start_contig = 0
    end_contig = 0
    
    assigned_barcodes.each_with_index do |assigned, i|
      if assigned.start_barcode == end_contig + 1   # range continues from previous contig
        end_contig = assigned.end_barcode
      elsif assigned.start_barcode < end_contig + 1 # error - overlapping ranges
        end_contig = assigned.end_barcode
      else                                          # gap between this range and previous => write out contig
        contigs.push({:start_range => start_contig, :end_range => end_contig}) if i > 0
        start_contig = assigned.start_barcode
        end_contig = assigned.end_barcode
      end
    end
    
    # write out last contig
    contigs.push({:start_range => start_contig, :end_range => end_contig})
    return contigs
  end
  
  def free_contigs(assigned_contigs)
    contigs = []
    start_contig = 1
    assigned_contigs.each do |assigned|
      contigs.push({:start_range => start_contig, :end_range => assigned[:start_range] - 1}) if assigned[:start_range].to_i > start_contig
      start_contig = assigned[:end_range] + 1
    end
    contigs.push({:start_range => start_contig, :end_range => 999999})
  end
end
