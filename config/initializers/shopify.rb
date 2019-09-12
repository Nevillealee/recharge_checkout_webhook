ShopifyAPI::Base.site = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_PW']}@#{ENV['SHOPIFY_SHOP']}.myshopify.com/admin"
ShopifyAPI::Base.api_version = "2019-07"
