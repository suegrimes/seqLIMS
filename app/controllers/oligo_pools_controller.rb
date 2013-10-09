class OligoPoolsController < ApplicationController

  # GET /oligo_pools
  def index
    @oligo_pools = Pool.includes(:primers).order(:tube_label).all
  end
  
  def show
    @oligo_pool = Pool.includes(:primers).order('primers.gene_code, primers.primer_name').find(params[:id])
  end

end
