# Facilitates Order tag updating
class PrepaidOrderHandler
  def initialize(order_id, line_items)
    #order_id has a class of Integer
    @order_id = order_id
    @line_items = line_items
    my_token = ENV['RECHARGE_STAGING_TOKEN']
    @my_header = {
      "X-Recharge-Access-Token" => my_token,
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  def start
    Resque.logger.info(
      "PrepaidOrderHandler.start received line_item['properties']: "\
      "#{@line_items[0]['properties']} \n ORDER ID: #{@order_id}"
    )
    my_props = @line_items[0]["properties"]
    found = false
    begin
      my_props.each do |p_hash|
        next unless p_hash["name"] == "3month_nocharge"
        Resque.logger.info "key value 3month_nocharge already exists. found: #{p_hash.inspect}"
        found = true
      end

      if found == false
        @line_items[0]["properties"] << { "name" => "3month_nocharge", "value" => true }
        my_hash = { "line_items" => @line_items }
        body = my_hash.to_json
        my_update_order = HTTParty.put(
          "https://api.rechargeapps.com/orders/#{@order_id}",
          :headers => @my_header,
          :body => body,
          :timeout => 80
        )
        Resque.logger.info "MY RECHARGE RESPONSE: #{my_update_order.parsed_response}"
      end

      return @line_items
    rescue StandardError => e
      Resque.logger.error("#{e.message}\nerror occured inside of #{my_props.inspect}")
    end
  end

end

# private
#
# def format_request(item_array)
#   new_item = item_array[0]
#   formatted_item = {
#     "properties" => new_item['properties'],
#     "quantity" => new_item['quantity'].to_i,
#     "sku" => new_item['sku'],
#     "product_title" => new_item['title'],
#     "variant_title" => new_item['variant_title'],
#     "product_id" => new_item['shopify_product_id'].to_i,
#     "variant_id" => new_item['shopify_variant_id'].to_i,
#     "subscription_id" => new_item['subscription_id'].to_i,
#   }
# end
#
# updated_order_data.each do |l_item|
#   my_line_item = {
#     "properties" => l_item['properties'],
#     "quantity" => l_item['quantity'].to_i,
#     "sku" => l_item['sku'],
#     "variant_title" => l_item['variant_title'],
#     "shopify_product_id" => l_item['shopify_product_id'].to_i,
#     "shopify_variant_id" => l_item['shopify_variant_id'].to_i,
#     "subscription_id" => l_item['subscription_id'].to_i,
#   }
#   updated_line_items.push(my_line_item)
# end
#
# my_hash = { "line_items" => updated_line_items }
# body = my_hash.to_json
# my_details = { "sku" => new_product.sku,
#                "product_title" => new_product.product_title,
#                "shopify_product_id" => new_product.product_id,
#                "shopify_variant_id" => new_product.variant_id,
#                "properties" => updated_line_items,
#              }
# params = { "subscription_id" => subscription_id, "action" => "switching_product", "details" => my_details }
# # When updating line_items, you need to provide all the data that was in
# # line_items before, otherwise only new parameters will remain! (from Recharge docs)
# my_update_order = HTTParty.put("https://api.rechargeapps.com/orders/#{my_order_id}", :headers => recharge_change_header, :body => body, :timeout => 80)
# Resque.logger.info "MY RECHARGE RESPONSE: #{my_update_order.parsed_response}"
