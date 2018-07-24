# loads custom tasks provided in resque gem
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
