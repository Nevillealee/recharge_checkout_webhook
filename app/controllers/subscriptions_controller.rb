class SubscriptionsController < ApplicationController
  # before_action :load_subscription

  def index
  end

  def create
    @sub_id = valid_params["subscription"]["id"]
    @status = valid_params["subscription"]["status"]
    @topic = request.headers["X-Recharge-Topic"]

    case @topic
    when 'subscription/created'
      if @status == 'ACTIVE'
        puts "subscription/created endpoint"
        Resque.enqueue(ShopifyCustomerTag, @sub_id)
        puts "X-Recharge-Topic: #{@topic}"
      end
    when 'subscription/updated'
      if @status == 'ACTIVE'
        puts "subscription/updated endpoint"
        Resque.enqueue(ShopifyCustomerTag, @sub_id)
        puts "X-Recharge-Topic: #{@topic}"
      end
    when 'subscription/activated'
      Resque.enqueue(ShopifyCustomerTag, @sub_id)
      puts "subscription/activated endpoint"
      puts "X-Recharge-Topic: #{@topic}"
    when 'subscription/cancelled'
      puts "subscription/cancelled endpoint"
      Resque.enqueue(TagRemovalBySub, @sub_id, 'subscription')
    else
      render :json => valid_params["subscription"].to_json ,:status => 400
      puts request.headers["X-Recharge-Topic"]
    end
  end

  private

  def valid_params
     params.permit(
       subscription:
       [:id,
         :customer_id,
         :status,
         :properties,
         :shopify_product_id,
         :product_title
        ]
      )
  end

end
