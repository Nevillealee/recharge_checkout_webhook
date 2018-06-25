class TagRemovalBySub
  @queue = :shopify

  def self.perform(obj_id, id_type, obj)
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.info "Job TagRemovalBySub started"
    UnTagger.new(obj_id, id_type, obj).remove
  end

end
