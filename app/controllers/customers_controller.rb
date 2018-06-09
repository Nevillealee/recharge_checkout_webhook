class CustomersController < ApplicationController
  def create
    case request.headers["X-Recharge-Topic"]
      when 'customer/created'
        my_id = recharge_cust_params["customer"]["shopify_customer_id"]
        Resque.enqueue(NewShopifyCustomerTag, my_id)
        puts request.headers["X-Recharge-Topic"]
      when 'customer/updated'
      when 'customer/activated'
      when 'customer/deactivated'
    else
      render :json => my_sub.to_json ,:status => 200
      puts request.headers["X-Recharge-Topic"]
    end
  end

  private

  def recharge_cust_params
     params.permit(
       customer:
       [:id,
         :hash,
         :email,
         :shopify_customer_id,
         :first_name,
         :last_name,
         :status
        ]
      )
  end


end
