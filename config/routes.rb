OpenCantine3::Application.routes.draw do

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

  # See how all your routes lay out with "rake routes"


  get 'admin' => 'admin#signin'
  get 'nouveau' => 'villes#nouveau_compte', :as => :nouveau
  get 'presence' => 'prestations#new_manual_classroom', :as => 'new_manual_classroom'


  get 'familles/autocomplete', to: 'familles#autocomplete' 

  get 'enfants/imprimer', to: 'enfants#imprimer'
  get 'enfants/liste', to: 'enfants#liste'

  get 'familles/listing', to: 'familles#listing'
  get 'familles/balance', to: 'familles#balance'

  get 'factures/new_all', to: 'factures#new_all'
  get 'factures/stats_mensuelle_params', to: 'factures#stats_mensuelle_params'
  get 'factures/print', to: 'factures#print'
  get 'factures/send_invoice', to: 'factures#send_invoice'
  post 'factures/create', to: 'factures#create'
  post 'factures/stats_mensuelle', to: 'factures#stats_mensuelle'
  get 'factures/facturation_speciale', to:'factures#facturation_speciale'
  post 'factures/facturation_speciale_do', to:'factures#facturation_speciale_do'

  get 'paiements/listing', to: 'paiements#listing'
  get 'paiements/print', to: 'paiements#print'

  get 'paiements/majdateremise', to: 'paiements#majdateremise'

  post "/prestations/new_manual_calc"
  get 'prestations/new_manual', to: 'prestations#new_manual'
  get 'prestations/edit_from_enfants', to: 'prestations#edit_from_enfants'
  get 'prestations/editions', to: 'prestations#editions'
  get 'prestations/new_manual_classroom', to: 'prestations#new_manual_classroom'
  post 'prestations/new_manual_classroom_check', to: 'prestations#new_manual_classroom_check'
  get 'prestations/print', to: 'prestations#print' 
  get 'prestations/stats_mensuelle_params', to: 'prestations#stats_mensuelle_params' 
  post 'prestations/stats_mensuelle', to: 'prestations#stats_mensuelle' 

  get 'admin/user_edit', to: 'admin#user_edit'
  get 'admin/users_admin', to: 'admin#users_admin'
  get 'admin/setup', to: 'admin#setup'
  get 'admin/bienvenue', to: 'admin#bienvenue'
  get 'admin/signout', to: 'admin#signout'
  get 'admin/import', to: 'admin#import'
  get 'admin/points_forts', to:'admin#points_forts'
  get 'admin/guide', to:'admin#guide'
  get 'admin/check_user', to: 'admin#check_user'

  patch 'admin/change_acces_portail', to: 'admin#change_acces_portail'
  post 'admin/user_add', to: 'admin#user_add'
  post "/admin/check_user"
  post "admin/import_do", to: 'admin#import_do'
  post 'upload/uploadFile', to: 'upload#uploadFile'

  get '/moncompte', to: 'moncompte#index'
  get 'moncompte/famillelogin', to: 'moncompte#famillelogin'
  get 'moncompte/mdpoublie', to:'moncompte#mdpoublie'
  get 'moncompte/famillelogout', to: 'moncompte#famillelogout'

  post 'moncompte/famillelogin', to: 'moncompte#famillelogin'
  post 'moncompte/mdpoublie_renvoyer', to: 'moncompte#mdpoublie_renvoyer'

  get 'moncompte/familleshow', to: 'moncompte#familleshow'
  get 'moncompte/famillefacture', to: 'moncompte#famillefacture'

  get 'villes/nouveau_compte_create', to: 'villes#nouveau_compte_create'
  post 'villes/nouveau_compte_create', to: 'villes#nouveau_compte_create'

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #  match ':controller(/:action(/:id))(.:format)'


  resources :familles
  resources :todos
  resources :blogs
  resources :vacances
  resources :villes
  resources :facture_chronos
  resources :mairies
  resources :factures
  resources :paiements
  resources :tarifs
  resources :classrooms
  resources :prestations 
  resources :enfants
  resources :users
  resources :upload
  resources :logs
    
  root 'familles#index'
  
end
