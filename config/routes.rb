Rails.application.routes.draw do
  root 'static_pages#root'

  resources :users do
    member do
      get "first", to: "users#first"
      get "second", to: "users#second"
    end
  end
end
