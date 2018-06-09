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
        Resque.enqueue(ShopifyCustomerTag, @sub_id)
        puts "X-Recharge-Topic: #{@topic}"
      end
    when 'subscription/updated'
      if @status == 'ACTIVE'
        Resque.enqueue(ShopifyCustomerTag, @sub_id)
        puts "X-Recharge-Topic: #{@topic}"
      end
    when 'subscription/activated'
      Resque.enqueue(ShopifyCustomerTag, @sub_id)
      puts "X-Recharge-Topic: #{@topic}"
    when 'subscription/cancelled'
      Resque.enqueue(TagRemovalBySub, @sub_id)
    else
      render :json => my_sub.to_json ,:status => 200
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
