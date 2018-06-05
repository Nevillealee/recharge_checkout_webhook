require 'test_helper'

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "can hit webhook url" do
    post subscriptions_url
  end

  test "/subscriptions endpoint routes to subs controller" do
    post "/subscriptions"
    assert_routing({ path: 'subscriptions', method: :post }, { controller: 'subscriptions', action: 'create' })
  end

  test "consumes json response from recharge" do
    params = ActionController::Parameters.new({
      subscription: {
        id: "123456789",
        status:  'ACTIVE'
      }
    })
    post "/subscriptions",
    params: { subscription: { id: "1233456789", status: "ACTIVE" }}
    json_response = JSON.parse(response.body)
    assert_equal '1233456789', json_response["subscription"]["id"]
    assert_response :success
  end
end
