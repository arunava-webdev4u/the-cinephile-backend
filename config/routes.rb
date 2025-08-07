Rails.application.routes.draw do
  # # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "api/v1/homepage#index"

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :register
        post :login
        delete :logout
      end

      resources :users, only: [ :show, :update, :destroy ]
      resources :search, only: [] do
        collection do
          get :name
          get :id
          get :trending
          get :popular
          get :top_rated
          get :upcoming
          get :now_playing
        end
      end

      resources :default_list, controller: :lists, type: "DefaultList", only: [ :index, :show ]
      resources :custom_list, controller: :lists, type: "CustomList"
    end
  end
end
