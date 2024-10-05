Rails.application.routes.draw do
  root 'conversions#new'
  resources :conversions, only: [:new, :create]
end
