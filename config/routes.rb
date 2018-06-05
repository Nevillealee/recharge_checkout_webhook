Rails.application.routes.draw do
  resource :subscriptions, only: [:create]
  root 'subscriptions#index'
end
