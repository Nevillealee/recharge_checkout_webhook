require 'rails_helper'

RSpec.describe PrepaidOrderHandler, type: :model do
  context "When 3month_nocharge key does not exist" do
    it "adds the 3month_nocharge kv to Order.line_items" do
      old_line_items = MOCK_ITEM
      new_line_items = PrepaidOrderHandler.new(1234567, old_line_items).start
      old_line_items[0]["properties"] << { "name" => "3month_nocharge", "value" => true }
      expect(new_line_items).to eq(old_line_items)
    end
  end
end
