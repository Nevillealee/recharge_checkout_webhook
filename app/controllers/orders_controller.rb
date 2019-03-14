class OrdersController < ApplicationController
  Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
  Resque.logger.level = Logger::INFO

  def index
  end

  def create
    @cust_id = valid_params["customer_id"]
    @topic = request.headers["X-Recharge-Topic"]

    case request.headers["X-Recharge-Topic"]
    when 'order/created'
      if (valid_params["is_prepaid"] == "1") && (valid_params["status"] == 'QUEUED')
        Resque.logger.info "order/created QUEUED order endpoint"
        puts "order/created QUEUED order endpoint"
        Resque.enqueue(QueuedOrderLabel, valid_params["id"])
        render :status => 200
      else
        Resque.logger.info "order/created prospect tag endpoint"
        Resque.enqueue(ProspectTag, @cust_id)
        puts @topic
        render :status => 200
      end
    else
      render :json => params["order"].to_json ,:status => 400
      puts request.headers["X-Recharge-Topic"]
    end
  end

  private

  def valid_params
     params.require(:order).permit(:id, :customer_id, :email,:is_prepaid, :line_items, :status)
  end
end
