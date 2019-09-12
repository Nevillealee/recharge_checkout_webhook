# Internal: Add 'recurring_subscription' tag to shopify customer object
# (found via recharge sub.customer_id -> recharge cust.shopify_customer_id ->
# shopify cust.id) if shopify customer object does not contain
# 'recurring_subscription' tag already.
class CustomerUpdatewSub
  def initialize(sub_id, sub)
    @sub_id = sub_id
    @sub = sub
    my_token = ENV['RECHARGE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
    @shopify_sleep_time = ENV['SHOPIFY_SLEEP_TIME'].to_i
  end

  def tag_customer
    if is_recurring_sub?(@sub)
      begin
        retries ||= 0
        my_customer = get_shopify_customer(@sub)
        my_tags = my_customer.tags.split(",")
        my_tags.map! {|x| x.strip}
        Resque.logger.info "Tagging Shopify Customer(#{my_customer.id}).."

        if my_tags.include?('recurring_subscription') || my_tags.include?('Inactive Subscriber')
          Resque.logger.info my_tags.inspect
          Resque.logger.info "customer doesnt need to be tagged\n"
        else
          Resque.logger.info "here what shopifys api returned from ID: #{my_customer.id}"
          my_tags << "recurring_subscription"
          # shopify wont accept tag string values without space AND comma delimited tokens!
          Resque.logger.info "old shopify customer object tags: #{my_customer.tags}"
          my_customer.tags = my_tags.join(",")
          my_customer.save
          Resque.logger.info "new shopify customer object tags: #{my_customer.tags}\n"
        end
      rescue => e
        retries += 1
        Resque.logger.info "ERROR: #{e.message}"
        Resque.logger.info "Attempt ##{retries}/3"
    	  retry if retries < 2
      end
    else
      Resque.logger.info "Subscription(#{@sub['id']}) isnt recurring! No changes made"
    end
  end

  # recurring ReCharge subscriptions wont have nil values for any of these sub attributes
  def is_recurring_sub?(sub)
    charge_int_freq = sub["charge_interval_frequency"]
    order_int_freq = sub["order_interval_frequency"]
    order_int_unit = sub["order_interval_unit"]
    Resque.logger.debug "Recharge Subscription RECURRING PROPERTY CHECK: \n"\
    "----->charge_interval_frequency: #{charge_int_freq}\n----->order_interval_frequency: "\
    "#{order_int_freq}\n----->order_interval_unit: #{order_int_unit}"
    return [charge_int_freq, order_int_freq, order_int_unit].all?
  end

  # Uses Recharge customer json to request Shopify Customer object
  def get_shopify_customer(sub)
    my_url = "https://api.rechargeapps.com/customers/#{sub["customer_id"]}"
    response = HTTParty.get(my_url, :headers => @my_header)
    my_response = JSON.parse(response.body)
    #recharge_cust is now a hash with string keys
    recharge_cust = my_response['customer']
    Resque.logger.info "Found recharge customer #{recharge_cust['id']}"
    sleep @shopify_sleep_time
    shopify_cust = ShopifyAPI::Customer.find(recharge_cust["shopify_customer_id"])
    return shopify_cust
  end

end
