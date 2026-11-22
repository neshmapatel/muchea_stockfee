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
  post "contact", to: "storefront#submit_contact"

  # Legal & Australian Consumer Law / Stripe Compliance Pages
  get "refund-policy", to: "storefront#refund_policy", as: :refund_policy
  get "returns", to: "storefront#refund_policy"
  get "terms", to: "storefront#terms", as: :terms
  get "privacy", to: "storefront#privacy", as: :privacy

  # SEO Dynamic XML Sitemap
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: :xml }

  # Customer / Member Authentication & Account Activation
  get "customer/register", to: "customers/registrations#new", as: :customer_register
  post "customer/register", to: "customers/registrations#create"
  get "register", to: "customers/registrations#new"
  get "customer/login", to: "customers/sessions#new", as: :customer_login
  post "customer/login", to: "customers/sessions#create"
  get "login", to: "customers/sessions#new"
  delete "customer/logout", to: "customers/sessions#destroy", as: :customer_logout
  get "customer/account", to: "customers/dashboard#show", as: :customer_account
  get "customer/dashboard", to: "customers/dashboard#show", as: :customer_dashboard

  # Shopping Cart
  get "cart", to: "cart#show", as: :cart
  post "cart/add", to: "cart#add_item", as: :add_to_cart
  patch "cart/update", to: "cart#update_item", as: :update_cart
  delete "cart/remove/:variant_id", to: "cart#remove_item", as: :remove_from_cart
  delete "cart/clear", to: "cart#clear", as: :clear_cart

  # Australian Checkout & Stripe Integration
  get "checkout", to: "checkout#new", as: :checkout
  post "checkout", to: "checkout#create", as: :process_checkout
  match "checkout/validate_postcode", to: "checkout#validate_postcode", via: [:get, :post], as: :checkout_validate_postcode
  post "checkout/payment_intent", to: "checkout#create_payment_intent", as: :checkout_payment_intent
  post "checkout/stripe_session", to: "checkout#create_stripe_session", as: :checkout_stripe_session
  get "checkout/stripe_return", to: "checkout#stripe_return", as: :checkout_stripe_return
  get "checkout/success/:order_number", to: "checkout#success", as: :checkout_success
  get "checkout/invoice/:order_number", to: "checkout#invoice", as: :tax_invoice

  # Stripe Webhooks (Live order payment status updates)
  post "webhooks/stripe", to: "webhooks#stripe", as: :stripe_webhook

  # Public WA Order & Shipment Tracking
  get "tracking", to: "tracking#index", as: :tracking_lookup
  get "tracking/:code", to: "tracking#show", as: :tracking

  # Warehouse Admin Authentication & Portal
  get "admin/login", to: "admin/sessions#new", as: :admin_login
  post "admin/login", to: "admin/sessions#create"
  delete "admin/logout", to: "admin/sessions#destroy", as: :admin_logout

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
        get :scanner
        post :scan_adjust
        get :import
        post :process_import
      end
    end
    resources :products
    resources :categories, except: [:show]
    resources :customers, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :inquiries, only: [:index, :show] do
      member do
        patch :resolve
        patch :reopen
      end
    end
    resources :users, except: [:show, :destroy] do
      member do
        patch :toggle_active
      end
    end
    resources :roles, except: [:show]
  end
end
