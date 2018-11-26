class SubscriptionsController < ApplicationController
  Resque.logger = Logger.new("#{Rails.root}/log/subscriptions_resque.log")

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
        Resque.logger.info "subscription/created endpoint"
        Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
        puts "#{@topic}"
        render :status => 200
      end
    when 'subscription/updated'
      if @status == 'ACTIVE'
        Resque.logger.info "subscription/updated endpoint"
        Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
        puts "#{@topic}"
        render :status => 200
      end
    when 'subscription/activated'
      Resque.enqueue(ShopifyCustomerTag, @sub_id, @sub)
      Resque.logger.info "subscription/activated endpoint"
      puts "#{@topic}"
      render :status => 200
    when 'subscription/cancelled'
      Resque.logger.info "subscription/cancelled endpoint"
      Resque.enqueue(TagRemovalBySub, @sub_id, 'subscription', @sub)
      puts "#{@topic}"
      render :status => 200
    else
      render :json => params["subscription"].to_json ,:status => 400
      puts request.headers["X-Recharge-Topic"]
    end
  end


end
