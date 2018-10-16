class CustomersController < ApplicationController
  Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
  Resque.logger.level = Logger::INFO

  def index
  end

  def create
    @shopify_id = valid_params["customer"]["shopify_customer_id"] if valid_params["customer"]
    @cust_id = valid_params["customer"]["id"] if valid_params["customer"]
    @topic = request.headers["X-Recharge-Topic"] if request.headers["X-Recharge-Topic"]

    case request.headers["X-Recharge-Topic"]
      when 'customer/created'
        Resque.enqueue(NewShopifyCustomerTag, @shopify_id)
        Resque.logger.info "customer created endpoint"
        puts request.headers["X-Recharge-Topic"]
        render :status => 200
      when 'customer/updated'
        Resque.enqueue(NewShopifyCustomerTag, @shopify_id)
        Resque.logger.info "customer updated endpoint"
        puts request.headers["X-Recharge-Topic"]
        render :status => 200
      when 'customer/activated'
        Resque.logger.info "customer/activated endpoint"
        Resque.enqueue(NewShopifyCustomerTag, @shopify_id)
        puts request.headers["X-Recharge-Topic"]
        render :status => 200
      when 'customer/deactivated'
        Resque.logger.info "customer deactivated endpoint"
        Resque.enqueue(TagRemovalBySub,  @cust_id, 'customer', params['customer'])
        puts request.headers["X-Recharge-Topic"]
        render :status => 200
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
