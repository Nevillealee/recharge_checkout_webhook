class TagRemovalBySub
  @queue :shopify

  def self.perform(sub_id)
    UnTagger.new(sub_id, 'subscription').remove
  end

end
