Rails.application.routes.draw do
  root 'subscriptions#index'
  resource :subscriptions, only: [:create, :index]
end
