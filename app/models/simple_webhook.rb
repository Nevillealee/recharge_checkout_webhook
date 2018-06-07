module SimpleWebhook
  class RechargeInfo
    def initialize
      @my_header = {
          "X-Recharge-Access-Token" => ENV['RECHARGE_STAGING_TOKEN']
      }
    end

    def list_webhooks
      #GET /webhooks/<id>
      webhooks = HTTParty.get("https://api.rechargeapps.com/webhooks", :headers => @my_header)
      puts webhooks.body.inspect
    end

    def create_webhook(hook, callback)
      
      # POST /webhooks
      temp_hash = { "webhook" => {"address" => callback, "topic" => hook} }
      body = temp_hash.to_json
      my_url = "https://api.rechargeapps.com/webhooks"
      new_webhook = HTTParty.post(
        my_url,
        :headers => @my_header,
        :body => body,
        :timeout => 80,
        :headers => {"content-type" => 'application/json'}
      )
      puts new_webhook.inspect
    end

    def delete_webhook(id)
      # DELETE /webhooks/<id>
      webhooks = HTTParty.delete("https://api.rechargeapps.com/webhooks/#{id}", :headers => @my_header)
      puts webhooks.body.inspect
    end
  end
end
