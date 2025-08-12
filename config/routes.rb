Rails.application.routes.draw do
  resources :professionals
  resources :patients
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication
  devise_for :users

  # Dashboards pós autenticação
  get "/dashboard", to: "dashboards#show", as: :dashboard
  get "/dashboard/professionals", to: "dashboards#professionals", as: :professionals_dashboard
  get "/dashboard/patients", to: "dashboards#patients", as: :patients_dashboard

  # Root
  root to: "dashboards#show"

  # API
  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index, :show ]
    end
  end
end
