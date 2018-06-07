class SubscriptionsController < ApplicationController
  # before_action :load_subscription

  def index
  end

  def create
    my_sub = load_subscription(recharge_sub_params["subscription"]["id"])
    # first arg: class of worker, 2nd arg: optional model passed in
    # model gets converted into json in background, dont pass in complex
    # active record objects, individual attributes are preferred
    Resque.enqueue(ShopifyCustomerTag, my_sub["id"])
    render :json => my_sub.to_json ,:status => 200
  end

  private
  def load_subscription(sub_id)
    return RechargeSubscription.find(sub_id)
  end

  def recharge_sub_params
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
