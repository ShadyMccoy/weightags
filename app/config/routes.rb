Rails.application.routes.draw do
  resource  :session
  resources :passwords, param: :token

  # Self-serve signup: creates a user, an org, and an admin membership (A1/D2).
  get  "sign_up", to: "registrations#new",    as: :sign_up
  post "sign_up", to: "registrations#create"

  # Org creation + multi-org switching (A1).
  resources :orgs, only: %i[new create]
  post "switch_org/:id", to: "orgs#switch", as: :switch_org

  # The reconciliation surface.
  resources :tags, only: %i[index show] do
    member do
      post  :accept
      post  :dispute
      post  :compromise
      post  :accept_compromise
      post  :note
      patch :weigh, action: :edit_weigh
      post  :split   # separate my weigh onto its own shipment (entity resolution)
      post  :merge   # fold this shipment into another (target_id)
    end
  end

  # Smart-pairing suggestions: mutual confirmation before a fuzzy match pairs (B2).
  resources :suggestions, only: [] do
    member do
      post :confirm
      post :reject
    end
  end

  # Ingest: direct scale-house entry (A4) and CSV import (A3).
  resources :weighs, only: %i[new create]
  resources :csv_imports, only: %i[new create] do
    collection { post :commit }
  end

  # Invoice batches: sender marks closed weighs invoiced; both sides view + print (C4).
  resources :invoice_batches, only: %i[index new create show] do
    member { get :pdf }
  end
  # Public, indexable record-verification page (product-led distribution).
  get "verify/:token", to: "verifications#show", as: :verify

  # In-app notifications inbox (D4).
  resources :notifications, only: %i[index update] do
    collection { post :read_all }
  end

  # Headless ingest API (charter: "production public API (v2)"). One simple
  # outward "weigh tag" object; upload weighs and sync statuses. Bearer-token auth.
  namespace :api do
    namespace :v1 do
      resources :weigh_tags, only: %i[index show create]
    end
  end

  # Public API reference: OpenAPI 3.1 spec + a rendered Redoc page (no auth).
  get "api/docs",     to: "api_docs#show", as: :api_docs
  get "openapi.yaml", to: "api_docs#spec", as: :openapi_spec

  # Self-serve API key management (admin only).
  resources :api_keys, only: %i[index create destroy]

  # System-of-record extras and org management.
  resources :activity, only: :index                      # C1 cross-tag feed
  resources :partnerships, only: %i[index update]         # C3 tolerances + windows
  resources :members, only: %i[index create update destroy] # D1 admin management

  # Ghost-account invite & org claim (A5).
  get  "claim/:token", to: "claims#show",   as: :claim
  post "claim/:token", to: "claims#create"

  # Domain verification + same-domain admin recovery (D3).
  resource :domain, only: %i[show update], controller: "domains" do
    post :verify_dns, on: :member
  end
  get "domain/confirm/:token", to: "domains#confirm", as: :confirm_domain
  resources :admin_recoveries, only: %i[index create]

  # Landing page (A2).
  root "pages#home"

  # Health check for continuous deploy / tag balancers (G0).
  get "up" => "rails/health#show", as: :rails_health_check
end
