# Facilitates Order tag updating
class PrepaidOrderHandler
  def initialize(order_id)
    #order_id has a class of Integer
    @order_id = order_id
    my_token = ENV['RECHARGE_ACTIVE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def start
    return @order_id
  end
end
