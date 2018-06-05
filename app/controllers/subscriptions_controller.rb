class SubscriptionsController < ApplicationController
  # before_action :load_subscription

  def index
  end

  def create
    render :json => params.to_json ,:status => 200
  end

  private

  def load_subscription
    @mysub = RechargeSubscription.find()
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
