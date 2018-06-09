Rails.application.routes.draw do
  resource :customers, only: [:create]
  root 'subscriptions#index'
  resource :subscriptions, only: [:create, :index]
end
