ActionController::Routing::Routes.draw do |map|
  map.connect '', :controller => "welcome", :action => "index" 
  map.signup  '/signup', :controller => 'welcome',   :action => 'signup' 
  map.login  '/login',  :controller => 'welcome', :action => 'login'
  map.logout '/logout', :controller => 'welcome', :action => 'logout'
  
  # User tables, and other administrative tables
  map.resources :users
  map.forgot    '/forgot',                    :controller => 'users',     :action => 'forgot'  
  map.reset     'reset/:reset_code',          :controller => 'users',     :action => 'reset'
  
  map.resources :researchers
  map.resources :consent_protocols
  map.resources :protocols
  map.resources :categories
  map.resources :storage_locations 
  
  map.protocol_type 'protocol_type', :controller => 'protocols', :action => 'query_params'
  
  # Routes for ordering chemicals & supplies
  map.resources :orders
  map.resources :items,  :collection => {:auto_complete_for_item_description => :get,
                                         :auto_complete_for_company_name     => :get,
                                         :auto_complete_for_catalog_nr       => :get}
  
  map.view_items 'view_items',       :controller => 'items',  :action => 'get_params'
  map.list_items 'list_items',       :controller => 'items',  :action => 'list_selected'
  map.notordered 'unordered_items',  :controller => 'items',  :action => 'list_unordered_items'
  map.edit_order_items 'edit_items', :controller => 'orders', :action => 'edit_order_items'
  map.view_orders 'view_orders',     :controller => 'orders', :action => 'get_params'
  
  # Routes for patients
  map.resources :patients
  map.modify_patient  'modify_patient',  :controller => 'patients', :action => 'edit_params'
  map.encrypt_patient 'encrypt_patient', :controller => 'patients', :action => 'loadtodb'
  
  # Routes for clinical samples/sample characteristics
  map.resources :sample_characteristics
  map.resources :pathologies
  
  map.add_pt_sample       'patient_sample',      :controller => 'sample_characteristics', :action => 'new_sample'
  map.modify_sample       'modify_sample',       :controller => 'sample_characteristics', :action => 'edit_params'
  map.new_path_rpt        'new_pathology',       :controller => 'pathologies',            :action => 'new_params'
  
  map.clinical_query      'clinical_query',      :controller => 'sample_characteristics', :action => 'query_params'
  map.clinical_list       'clinical_list',       :controller => 'sample_characteristics', :action => 'list_selected'
  
  # Routes for physical source samples
  map.resources :samples
  map.resources :sample_queries, :only => :index
  map.resources :histologies,    :collection => {:auto_complete_for_barcode_key => :get}
  
  map.new_psample         'new_psample',         :controller => 'samples',                :action => 'new_processing'
  map.upd_sample          'upd_sample',          :controller => 'samples',                :action => 'edit_params'
  map.edit_samples        'edit_samples',        :controller => 'samples',                :action => 'edit_by_barcode'
  map.edit_he_slide       'edit_he_slide',       :controller => 'histologies',            :action => 'edit_by_barcode'
  
  map.unprocessed_query 'unprocessed_query',   :controller => 'sample_queries', :action => 'new_query'
  map.samples_list      'samples_for_patient', :controller => 'sample_queries', :action => 'list_samples_for_patient'
  map.samples_list1     'samples_from_source', :controller => 'sample_queries', :action => 'list_samples_for_characteristic'
  
  # Routes for dissected samples
  map.resources :dissected_samples 
  #map.dissected_query   'dissected_query',   :controller => 'samples',           :action => 'query_params', :stype => 'dissected'
  
  # Routes for extracted samples
  map.resources :processed_samples,  :collection => {:auto_complete_for_barcode_key => :get}
  map.resources :psample_queries,    :only => :index
  
  map.edit_psamples     'edit_psamples',     :controller => 'processed_samples', :action => 'edit_by_barcode'
  
  map.samples_processed 'samples_processed', :controller => 'processed_samples', :action => 'show_by_sample'
  map.processed_query   'processed_query',   :controller => 'psample_queries',   :action => 'new_query'
  
  # Routes for molecular assays
  map.resources :prepared_samples
  map.ps_upload 'ps_upload', :controller => 'prepared_samples', :action => 'upload_file'
  
  # Routes for sequencing libraries
  map.resources :seq_libs,     :collection => {:auto_complete_for_barcode_key => :get},
                               :member => {:create_splex => :post,
                                           :create_mplex => :post}
  map.resources :seqlib_lanes
  map.resources :seqlib_queries, :only => :index
  
  map.new_lib_S   'new_lib_S',       :controller => 'seq_libs',    :action => 'new',   :multiplex => 'single'
  map.new_lib_M   'new_lib_M',       :controller => 'seq_libs',    :action => 'new',   :multiplex => 'multi'
  map.lib_qc      'lib_qc',          :controller => 'seqlib_lanes', :action => 'export_libqc'
  map.lib_query   'lib_query',       :controller => 'seqlib_queries', :action => 'new_query'
  
  # Routes for flow cells/sequencing runs
  map.resources :flow_cells,  :collection => {:auto_complete_for_sequencing_key => :get}
  map.resources :analysis_qc
  map.resources :index_tags
  map.resources :alignment_refs
  map.resources :seq_machines, :collection => {:auto_complete_for_machine_desc => :get}
  map.resources :flowcell_queries, :only => :index
  
  map.auto_complete ':controller/:action?:search', 
     :requirements => { :action => /auto_complete_for_\S+/ },
     :conditions => { :method => :get }
  
  map.flow_cell_setup 'flow_cell_setup', :controller => 'flow_cells', :action => 'setup_params'
  map.flow_cell_qc    'seq_run_qc',      :controller => 'flow_cells', :action => 'show_qc'
  map.seq_run_query   'seq_run_query',   :controller => 'flowcell_queries', :action => 'new_query'
  
  # Routes for handling storage devices and sequencing run directories
  map.resources :storage_devices
  map.resources :run_dirs
  map.dir_params 'dir_params',  :controller => 'run_dirs', :action => 'get_params'
  
  # Routes for handling file attachments
  map.resources :attached_files
  map.attach_params 'attach_params',   :controller => 'attached_files', :action => 'get_params'
  map.display_file 'display_file/:id', :controller => 'attached_files', :action => 'show'
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end