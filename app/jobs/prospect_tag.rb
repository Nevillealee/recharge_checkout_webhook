# Public: Background job within prospect_tag_removal queue
# default class method invokes ProspectRemover service
class ProspectTag
  @queue = :prospect_tag_removal

  def self.perform(cust_id)
    Resque.logger = Logger.new("#{Rails.root}/log/prospect_tag_removal.log")
    Resque.logger.info "Job ProspectTagRemoval started"
    ProspectRemover.new(cust_id).start
  end

end
