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
      Resque.logger.info "order/created endpoint"
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
         :last_name]
      )
  end


end
