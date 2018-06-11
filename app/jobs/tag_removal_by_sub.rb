class TagRemovalBySub
  @queue = :shopify

  def self.perform(obj_id, id_type)
    UnTagger.new(obj_id, id_type).remove
  end

end
