Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "storefront#index"

  resources :categories, only: [:show], param: :slug
  resources :products, only: [:index, :show], param: :slug

  # Rural Information & Store Pages
  get "delivery-schedule", to: "storefront#delivery_schedule", as: :delivery_schedule
  get "drive-thru-pickup", to: "storefront#drive_thru_pickup", as: :drive_thru_pickup
  get "about", to: "storefront#about", as: :about
  get "contact", to: "storefront#contact", as: :contact

  # SEO Dynamic XML Sitemap
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: :xml }

  # Shopping Cart
  get "cart", to: "cart#show", as: :cart
  post "cart/add", to: "cart#add_item", as: :add_to_cart
  patch "cart/update", to: "cart#update_item", as: :update_cart
  delete "cart/remove/:variant_id", to: "cart#remove_item", as: :remove_from_cart
  delete "cart/clear", to: "cart#clear", as: :clear_cart

  # Australian Checkout & ATO Tax Invoicing
  get "checkout", to: "checkout#new", as: :checkout
  post "checkout", to: "checkout#create", as: :process_checkout
  get "checkout/success/:order_number", to: "checkout#success", as: :checkout_success
  get "checkout/invoice/:order_number", to: "checkout#invoice", as: :tax_invoice

  # Public WA Order & Shipment Tracking
  get "tracking", to: "tracking#index", as: :tracking_lookup
  get "tracking/:code", to: "tracking#show", as: :tracking

  # Warehouse Admin Portal
  namespace :admin do
    root to: "dashboard#index"
    resources :orders, only: [:index, :show, :update] do
      member do
        patch :advance_status
        get :packing_slip
      end
    end
    resources :inventory, only: [:index] do
      collection do
        post :quick_adjust
      end
    end
    resources :products, only: [:index, :show]
  end
end
