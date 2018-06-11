class CustomersController < ApplicationController
  def create
    @shopify_id = valid_params["customer"]["shopify_customer_id"]
    @cust_id = valid_params["customer"]["id"]
    @topic = request.headers["X-Recharge-Topic"]

    case request.headers["X-Recharge-Topic"]
      when 'customer/created'
        Resque.enqueue(NewShopifyCustomerTag, @shopify_id)
        puts "created endpoint"
        puts request.headers["X-Recharge-Topic"]
      when 'customer/updated'
        Resque.enqueue(NewShopifyCustomerTag, @shopify_id)
        puts "updated endpoint"
        puts request.headers["X-Recharge-Topic"]
      when 'customer/activated'
        Resque.enqueue(NewShopifyCustomerTag, @shopify_id)
        puts "activated endpoint"
        puts request.headers["X-Recharge-Topic"]
      when 'customer/deactivated'
        puts "deactivated endpoint"
        Resque.enqueue(TagRemovalBySub,  @cust_id, 'customer')
    else
      render :json => valid_params["customer"].to_json ,:status => 400
      puts request.headers["X-Recharge-Topic"]
    end
  end

  private

  def valid_params
     params.permit(
       customer:
       [:id,
         :hash,
         :email,
         :shopify_customer_id,
         :first_name,
         :last_name,
         :status]
      )
  end


end
