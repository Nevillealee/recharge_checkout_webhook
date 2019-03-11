# Public: Background job within prepaid_order_labeling queue
# default class method invokes QueuedOrderMark service
class QueuedOrderLabel
  @queue = :queued_order_label
  def self.perform(order_id)
    Resque.logger = Logger.new("#{Rails.root}/log/resque.log")
    Resque.logger.level = Logger::DEBUG
    Resque.logger.datetime_format = '%F %Z %T '
    Resque.logger.info "Job prepaid order labeling started"
    PrepaidOrderHandler.new(order_id).start
  end

end
