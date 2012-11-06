class OligoPoolsController < ApplicationController

  # GET /oligo_pools
  def index
    @oligo_pools = Pool.find(:all, :include => :primers, :order => 'tube_label')
  end
  
  def show
    @oligo_pool = Pool.find(params[:id], :include => :primers, :order => 'primers.gene_code, primers.primer_name')
  end

end
