Rails.application.routes.draw do
  get "api/v1/homepage/index"
  post "api/v1/auth/login", to: "api/v1/auth#login"
  post "api/v1/auth/register", to: "api/v1/auth#register"

  get "api/v1/users", to: "api/v1/users#index"
  # post "api/v1/users", to: "api/v1/users#create"
  get "api/v1/users/:id", to: "api/v1/users#show"
  put "api/v1/users/:id", to: "api/v1/users#update"
  delete "api/v1/users/:id", to: "api/v1/users#delete"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "api/v1/homepage#index"
end
