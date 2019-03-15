# Facilitates Order tag updating
class PrepaidOrderHandler
  def initialize(order_id, line_items)
    #order_id has a class of Integer
    @order_id = order_id
    @line_items = line_items
    my_token = ENV['RECHARGE_ACTIVE_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token
    }
  end

  def start
    Resque.logger.info(
      "PrepaidOrderHandler.start received line_item['properties']: "\
      "#{ @line_items[0]['properties'] } \n ORDER ID: #{@order_id}"
    )
    my_props = @line_items[0]["properties"]
    found = false
    result = ""
    my_props.each do |p_hash|
      if p_hash["name"] == "3month_nocharge"
        found = true
        Resque.logger.info "key value 3month_nocharge already exists"
        result = "key value 3month_nocharge already exists"
      end
    end

    if found == false
      my_props << { "name" => "3month_nocharge", "value" => true }
      @line_items[0]["properties"] = my_props
      result = @line_items
    end
    return result
  end

end
