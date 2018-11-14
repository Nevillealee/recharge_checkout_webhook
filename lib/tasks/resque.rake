# loads custom tasks provided in resque gem
Dir["#{Rails.root}/app/services/*.rb"].each { |file| require file }
include GetDataAPI
 require "resque/tasks"
# load up rails environment so we have access to
# all models inside of our workers
task "resque:setup" => :environment

namespace :webhook do
  desc 'get list of active recharge webhooks'
  task list: :environment do
    SimpleWebhook::RechargeInfo.new.list_webhooks
  end

  desc 'create new webhook on recharge: args = (topic, callbackurl)'
  # TOPICS: subscription/created, subscription/updated, subscription/activated, subscription/cancelled
  # customer/created, customer/updated, customer/activated, customer/deactivated
  task :create, [:topic, :callback] => [:environment] do |t, args|
    SimpleWebhook::RechargeInfo.new.create_webhook(*args)
  end
end

desc 'Request from API and persist all shopify customer data'
task :pull_shopify_cust => :environment do
  ShopifyCustomer.delete_all
  ActiveRecord::Base.connection.reset_pk_sequence!('shopify_customers')
  GetDataAPI.save_all_shopify_customers
end

desc 'remove prospect tag from active subscribers'
task :remove_prospect => :environment do
  GetDataAPI.remove_prospect
end
