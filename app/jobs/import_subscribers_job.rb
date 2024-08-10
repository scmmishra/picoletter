class ImportSubscribersJob < ApplicationJob
  queue_as :default

  def initialize(file, newsletter, source)
    @file = file
    @source = source
  end

  def perform
    import_service.new(@file, @newsletter).call
  end

  def import_service
    case @source
    when "buttondown"
      Import::Buttondown
    end
  end
end
