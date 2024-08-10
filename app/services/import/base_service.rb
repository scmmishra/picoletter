require "csv"
require "date"

class Import::BaseService
  def initialize(file, newsletter)
    @file = file
    @newsletter = newsletter
  end

  def perform
    CSV.foreach(@file.path, headers: true) do |row|
      subscriber_attributes = map_fields(row)
      subscriber = @newsletter.subscribers.find_or_initialize_by(email: subscriber_attributes[:email])
      subscriber.assign_attributes(subscriber_attributes)
      subscriber.status = determine_status(row)
      subscriber.created_via = "import"
      subscriber.save!
    end
  end

  def field_mapping
    raise NotImplementedError
  end

  def determine_status(row)
    raise NotImplementedError
  end

  private

  def map_fields(row)
    field_mapping.each_with_object({}) do |(csv_field, db_field), mapped|
      value = row[csv_field.to_s]
      mapped[db_field] = parse_value(db_field, value)
    end
  end

  def parse_value(field, value)
    return nil if value.nil? || value.empty?

    case field
    when :created_at, :verified_at, :unsubscribed_at
      parse_date(value)
    else
      value
    end
  end

  def parse_date(value)
    Date.parse(value)
  rescue Date::Error
    nil
  end
end
