class OrdersController < ApplicationController
  Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
  Resque.logger.level = Logger::INFO

  def index
  end

  def create
    @cust_id = valid_params["order"]["customer_id"] if valid_params["order"]
    @topic = request.headers["X-Recharge-Topic"] if request.headers["X-Recharge-Topic"]
    case request.headers["X-Recharge-Topic"]
    when 'order/created'
      if valid_params["order"]["is_prepaid"] == 1
        @order_id = valid_params["order"]["id"]
        Resque.logger.info "order/created QUEUED order endpoint"
        puts "order/created QUEUED order endpoint"
        Resque.enqueue(QueuedOrderLabel, @order_id)
      end
      Resque.logger.info "order/created prospect tag endpoint"
      Resque.enqueue(ProspectTag, @cust_id)
      puts @topic
      render :status => 200
    else
      render :json => valid_params["order"].to_json ,:status => 400
      puts request.headers["X-Recharge-Topic"]
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
         :last_name,
         :is_prepaid,
       ]
      )
  end
end
