Resque.logger = Logger.new(STDOUT)
Resque.logger.formatter = Resque::QuietFormatter.new
Resque.logger.level = Logger::DEBUG
