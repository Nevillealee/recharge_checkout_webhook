class SubscriptionsController < ApplicationController

  def index
  end

  def create
    @sub_id = params["subscription"]["id"]
    @sub = params["subscription"]
    @status = params["subscription"]["status"]
    @topic = request.headers["X-Recharge-Topic"]

    case @topic
    when 'subscription/created'
      if @status == 'ACTIVE'
        puts "subscription/created endpoint"
        Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
        puts "X-Recharge-Topic: #{@topic}"
        render :status => 200
      end
    when 'subscription/updated'
      if @status == 'ACTIVE'
        puts "subscription/updated endpoint"
        Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
        puts "X-Recharge-Topic: #{@topic}"
        render :status => 200
      end
    when 'subscription/activated'
      Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
      puts "subscription/activated endpoint"
      puts "X-Recharge-Topic: #{@topic}"
      render :status => 200
    when 'subscription/cancelled'
      puts "subscription/cancelled endpoint"
      Resque.enqueue(TagRemovalBySub, @sub_id, 'subscription')
      render :status => 200
    else
      render :json => params["subscription"].to_json ,:status => 400
      puts request.headers["X-Recharge-Topic"]
    end
  end

  # private
  #
  # def params
  #    params.permit(
  #      subscription:
  #      [:id,
  #        :customer_id,
  #        :status,
  #        :properties,
  #        :shopify_product_id,
  #        :product_title
  #       ]
  #     )
  # end

end
