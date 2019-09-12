class SubscriptionsController < ApplicationController
  def index
  end

  def create
    @sub_id = params["subscription"]["id"]
    @sub = params["subscription"]
    @status = params["subscription"]["status"]
    @topic = request.headers["X-Recharge-Topic"]

   logger.info "Subscription Controller reached"
    case @topic
    when 'subscription/created'
      logger.info "subscription/created endpoint"
      Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
      logger.info "#{@topic}"
      render :status => 200
    when 'subscription/activated'
      Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
      logger.info "subscription/activated endpoint"
      logger.info "#{@topic}"
      render :status => 200
    when 'subscription/cancelled'
      logger.info "subscription/cancelled endpoint"
      Resque.enqueue(TagRemovalBySub, @sub)
      logger.info "#{@topic}"
      render :status => 200
    else
      render :json => params["subscription"].to_json ,:status => 400
      logger.error request.headers["X-Recharge-Topic"]
    end
  end


end
