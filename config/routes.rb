Rails.application.routes.draw do
  root 'subscriptions#index'
  resources :orders, only: [:create, :index]
  resources :customers, only: [:create, :index]
  resources :subscriptions, only: [:create, :index]
end
