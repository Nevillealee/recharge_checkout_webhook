# Internal: Using subscription json recieved from ReCharge,
# remove 'recurring_subscription' tag from matching shopify customer object
# if customer no longer has a recurring subscription.
class UnTagger
  include Recurring
  def initialize(sub)
    @recharge_sub = sub
    my_token = ENV['RECHARGE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
    @shopify_sleep_time = ENV['SHOPIFY_SLEEP_TIME'].to_i
  end

  def remove
    recharge_customer = Customer.find_by_customer_id(@recharge_sub['customer_id'])
    Resque.logger.info "Recharge customer id: #{recharge_customer.customer_id}"
    my_url = "https://api.rechargeapps.com/subscriptions?customer_id=#{recharge_customer.customer_id}&status=ACTIVE"
    response = HTTParty.get(my_url, :headers => @my_header)
    my_response = JSON.parse(response.body)

    # subs_array is now an array of hashes with string keys
    active_subs = my_response['subscriptions']
    Resque.logger.info "#{active_subs.size} ACTIVE SUBS RETURNED FORM RECHARGE: #{active_subs.inspect}"
    changes_made = false

    if active_subs.size < 1 || no_recurring_subs?(active_subs)
      sleep @shopify_sleep_time
      my_shopify_cust = ShopifyAPI::Customer.find(recharge_customer.shopify_customer_id)
      my_tags = my_shopify_cust.tags.split(",")
      my_tags.map! {|x| x.strip}
      Resque.logger.info "Shopify Customer tags before: #{my_shopify_cust.tags.inspect}"

      my_tags.each do |x|
        if x.include?('recurring_subscription')
          my_tags.delete(x)
          changes_made = true
        end
      end

      if changes_made
        my_shopify_cust.tags = my_tags.join(",")
        my_shopify_cust.save
        Resque.logger.info "Shopify Customer tags after: #{my_shopify_cust.tags.inspect}"
        Resque.logger.info "tag removed"
      else
        Resque.logger.info "recurring_subscription tag not found in: #{my_shopify_cust.tags.inspect}"
        Resque.logger.info "No changes made"
      end
    else
      Resque.logger.info "Shopify Customer tags will not be removed, customer has other RECURRING subscriptions"
    end
  end

  # sub_array should be array of hashes with string keys
  def no_recurring_subs?(sub_array)
    sub_array.none? do |sub|
      is_recurring_sub?(sub)
    end
  end
end
