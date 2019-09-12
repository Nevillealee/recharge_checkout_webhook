class TagRemovalBySub
  @queue = :tag_removal
  def self.perform(recharge_sub)
    Resque.logger = Logger.new("#{Rails.root}/log/recurring_subscription_removal.log")
    Resque.logger.info "Job TagRemovalBySub started"
    UnTagger.new(recharge_sub).remove
  end
end
