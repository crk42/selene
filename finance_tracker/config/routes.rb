Rails.application.routes.draw do
  root "dashboard#index"
  
  resources :transactions
  get "dashboard", to: "dashboard#index"
end
