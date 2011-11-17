class OligoPoolsController < ApplicationController

  # GET /oligo_pools
  def index
    @oligo_pools = Pool.find(:all, :order => 'tube_label')
  end

end
