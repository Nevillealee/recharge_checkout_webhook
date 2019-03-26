require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  context "Recharge webhook event fires" do
    before(:each) do
      ResqueSpec.reset!
    end
    it "sanitizers order params" do
      request.headers['X-Recharge-Topic'] = "order/created"
      post :create, :params => { :order =>
        { :id => 1234567, :is_prepaid => 1, :status => "QUEUED", :customer_id => 11111111 }
      }
      expect(response).to have_http_status(200)
    end
    it "enqueues QueuedOrderLabel job" do
      request.headers['X-Recharge-Topic'] = "order/created"
      post :create, :params => { :order =>
        { :id => 1234567, :is_prepaid => 1, :status => "QUEUED", :customer_id => 11111111, :line_items => BASE_ITEMS.to_json }
      }
      expect(QueuedOrderLabel).to have_queued("1234567", BASE_ITEMS.to_json).in(:queued_order_label)
      expect(QueuedOrderLabel).to have_queue_size_of(1)
    end
  end
end
