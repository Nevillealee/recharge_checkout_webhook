class OrdersController < ApplicationController
  def index
  end

  def create
    logger.info "Order Controller reached"
    @cust_id = valid_params["order"]["customer_id"] if valid_params["order"]
    @topic = request.headers["X-Recharge-Topic"] if request.headers["X-Recharge-Topic"]

    if request.headers["X-Recharge-Topic"] == 'order/created'
      logger.info "order/created endpoint"
      Resque.enqueue(ProspectTag, @cust_id)
      logger.info @topic
      render :status => 200
    else
      render :json => valid_params["order"].to_json ,:status => 400
      logger.error request.headers["X-Recharge-Topic"]
    end

  end

  private

  def valid_params
     params.permit(
       order:
       [:id,
         :customer_id,
         :email,
         :first_name,
         :last_name]
      )
  end

end
