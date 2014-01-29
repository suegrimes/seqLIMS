# == Schema Information
#
# Table name: assay_genes
#

class AssayGene < ActiveRecord::Base
  belongs_to :molecular_assay
end