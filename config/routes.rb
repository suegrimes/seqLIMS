SeqLIMS::Application.routes.draw do
  
  match '' => 'welcome#index'
  match '/signup' => 'welcome#signup', :as => :signup
  match '/login' => 'welcome#login', :as => :login
  match '/user_login' => 'welcome#user_login'
  match '/logout' => 'welcome#logout', :as => :logout
  
  resources :users
  match '/forgot' => 'users#forgot', :as => :forgot
  match 'reset/:reset_code' => 'users#reset', :as => :reset
  
  resources :researchers
  resources :publications
  resources :consent_protocols
  resources :protocols
  resources :categories
  resources :freezer_locations
  resources :sample_storage_containers, :only => :index
  match 'sstorage_query' => 'sample_storage_containers#new_query', :as => :sstorage_query
  
  match 'protocol_type' => 'protocols#query_params', :as => :protocol_type
  
  # Routes for ordering chemicals & supplies
  resources :orders do
    member do
      get :edit_order_items
    end
    collection do
      get :new_query, :as => :view_orders
    end
  end
  resources :items do
    collection do
      get :autocomplete_item_company_name
      get :autocomplete_item_description
      get :autocomplete_item_company_name
      get :autocomplete_item_catalog_nr
    end  
  end

  match 'view_items' => 'items#new_query', :as => :view_items
  match 'list_items' => 'items#list_selected', :as => :list_items
  match 'unordered_items' => 'items#list_unordered_items', :as => :notordered
  match 'edit_items' => 'orders#edit_order_items', :as => :edit_order_items
  match 'view_orders' => 'orders#new_query', :as => :view_orders
  
  # Routes for patients
  resources :patients
  match 'modify_patient' => 'patients#edit_params', :as => :modify_patient
  match 'encrypt_patient' => 'patients#loadtodb', :as => :encrypt_patient
  
  # Routes for reserved barcodes
  resources :assigned_barcodes
  match 'check_barcodes/available' => 'assigned_barcodes#check_barcodes', :as => :check_available_barcodes, :rtype => 'available'
  match 'check_barcodes/assigned' => 'assigned_barcodes#check_barcodes', :as => :list_assigned_barcodes, :rtype => 'assigned'
  
  # Routes for clinical samples/sample characteristics
  resources :sample_characteristics do
    member do
      get :add_new_sample
    end 
  end
  resources :pathologies
  
  match 'patient_sample' => 'sample_characteristics#new_sample', :as => :add_pt_sample
  match 'modify_sample' => 'sample_characteristics#edit_params', :as => :modify_sample
  match 'new_pathology' => 'pathologies#new_params', :as => :new_path_rpt
  
  match 'clinical_query' => 'sample_characteristics#query_params', :as => :clinical_query
  match 'clinical_list' => 'sample_characteristics#list_selected', :as => :clinical_list
  
  # Routes for physical source samples
  resources :samples do
    collection do
      get :auto_complete_for_barcode_key
    end
  end

  resources :sample_queries, :only => :index
  #match 'sample_query' => 'sample_queries#index', :as => :sample_query

  resources :histologies do
    collection do
      get :auto_complete_for_barcode_key
    end
  end

  match 'upd_sample' => 'samples#edit_params', :as => :upd_sample
  match 'edit_samples' => 'samples#edit_by_barcode', :as => :edit_samples
  match 'new_he_slide' => 'histologies#new_params', :as => :new_he_slide
  match 'edit_he_slide' => 'histologies#edit_by_barcode', :as => :edit_he_slide
  match 'unprocessed_query' => 'sample_queries#new_query', :as => :unprocessed_query
  match 'samples_for_patient' => 'sample_queries#list_samples_for_patient', :as => :samples_list
  match 'samples_from_source' => 'sample_queries#list_samples_for_characteristic', :as => :samples_list1
  match 'export_samples' => 'sample_queries#export_samples', :as => :export_samples
  
  # Routes for dissected samples
  resources :dissected_samples
  match 'new_dissection' => 'dissected_samples#new_params', :as => :new_dissection
  match 'add_dissection' => 'dissected_samples#new'
  
  # Routes for extracted samples
  resources :processed_samples do
    collection do
      get :auto_complete_for_barcode_key
    end
  end
  resources :psample_queries, :only => :index

  match 'new_extraction' => 'processed_samples#new_params', :as => :new_extraction
  match 'add_extraction' => 'processed_samples#new'
  match 'edit_psamples' => 'processed_samples#edit_by_barcode', :as => :edit_psamples
  match 'samples_processed' => 'processed_samples#show_by_sample', :as => :samples_processed
  match 'processed_query' => 'psample_queries#new_query', :as => :processed_query
  match 'export_psamples' => 'psample_queries#export_samples', :as => :export_psamples
  
  # Routes for molecular assays
  resources :molecular_assays do
    collection do
      get :auto_complete_for_extraction_barcode
      get :list_added
      get :auto_complete_for_barcode_key
      get :autocomplete_molecular_assay_source_sample_name
    end
    member do
      post :create_assays
    end 
  end
  match 'new_molecular_assay' => 'molecular_assays#new', :as => :new_molecular_assay
  match 'create_molecular_assays' => 'molecular_assays#create_assays', :as => :create_molecular_assays
  match 'populate_assays' => 'molecular_assays#populate_assays'

  resources :molassay_queries, :only => :index
  match 'mol_assay_query' => 'molassay_queries#new_query', :as => :mol_assay_query
  
  # Routes for sequencing libraries
  resources :seq_libs do
    collection do
      get :auto_complete_for_barcode_key
    end  
  end

  resources :mplex_libs do
    collection do
      get :auto_complete_for_barcode_key
    end
  end

  resources :oligo_pools, :only => [:index, :show]
  
  resources :seqlib_lanes
  resources :seqlib_queries, :only => :index
  
  match 'mplex_setup' => 'mplex_libs#setup_params', :as => :mplex_setup
  match 'lib_qc' => 'seqlib_lanes#export_libqc', :as => :lib_qc
  match 'lib_query' => 'seqlib_queries#new_query', :as => :lib_query
  
  # Routes for flow cells/sequencing runs
  resources :flow_cells do
    collection do
      get :auto_complete_for_sequencing_key
    end
    member do
      get :show_publications
      put :upd_for_sequencing
    end 
  end

  #match 'view_pubs' => 'flow_cells#show_publications', :as => :view_pubs
  resources :analysis_qc
  resources :index_tags
  resources :alignment_refs
  resources :seq_machines do
    collection do
      get :auto_complete_for_machine_desc
    end 
  end

  resources :flowcell_queries, :only => :index
  resources :align_qcs, :only => [:new, :create, :edit, :update]
  
  match ':controller/:action?:search' => '#index', :as => :auto_complete, :via => :get, :constraints => { :action => /auto_complete_for_\S+/ }

  match 'flow_cell_setup' => 'flow_cells#setup_params', :as => :flow_cell_setup
  match 'seq_run_qc' => 'flow_cells#show_qc', :as => :flow_cell_qc
  match 'seq_run_query' => 'flowcell_queries#new_query', :as => :seq_run_query
  
  # Routes for handling storage devices and sequencing run directories
  resources :storage_devices
  resources :run_dirs
  match 'del_run_dir' => 'run_dirs#del_run_dir', :as => :del_run_dir
  match 'dir_params' => 'run_dirs#get_params', :as => :dir_params
  
  # Routes for handling file attachments
  resources :attached_files
  match 'attach_params' => 'attached_files#get_params', :as => :attach_params
  match 'display_file/:id' => 'attached_files#show', :as => :display_file
  match 'attach_file' => 'attached_files#create'
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
