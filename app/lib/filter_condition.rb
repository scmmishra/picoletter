class FilterCondition
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Available filter types and their configurations
  FILTER_TYPES = {
    "label" => {
      display_name: "Label",
      operators: {
        "has" => { display: "has", jsonlogic: ->(value) { { "in" => [ value, { "var" => "labels" } ] } } },
        "not_has" => { display: "does not have", jsonlogic: ->(value) { { "!" => { "in" => [ value, { "var" => "labels" } ] } } } }
      },
      value_type: "select" # select, text, date, etc.
    }
    # Future filter types can be added here:
    # 'email' => {
    #   display_name: 'Email',
    #   operators: {
    #     'contains' => { display: 'contains', jsonlogic: ->(value) { { "in" => [value, { "var" => "email" }] } } },
    #     'not_contains' => { display: 'does not contain', jsonlogic: ->(value) { { "!" => { "in" => [value, { "var" => "email" }] } } } }
    #   },
    #   value_type: 'text'
    # },
    # 'created_at' => {
    #   display_name: 'Signup Date',
    #   operators: {
    #     'after' => { display: 'after', jsonlogic: ->(value) { { ">" => [{ "var" => "created_at" }, value] } } },
    #     'before' => { display: 'before', jsonlogic: ->(value) { { "<" => [{ "var" => "created_at" }, value] } } }
    #   },
    #   value_type: 'date'
    # }
  }.freeze

  attribute :field, :string
  attribute :operator, :string
  attribute :value, :string

  validates :field, inclusion: { in: FILTER_TYPES.keys }
  validates :operator, presence: true
  validates :value, presence: true

  validate :operator_valid_for_field

  def self.available_fields
    FILTER_TYPES.keys
  end

  def self.field_display_name(field)
    FILTER_TYPES[field]&.dig(:display_name) || field.humanize
  end

  def self.operators_for_field(field)
    FILTER_TYPES[field]&.dig(:operators)&.keys || []
  end

  def self.operator_display(field, operator)
    FILTER_TYPES[field]&.dig(:operators, operator, :display) || operator.humanize
  end

  def self.value_type_for_field(field)
    FILTER_TYPES[field]&.dig(:value_type) || "text"
  end

  def display_text
    field_name = self.class.field_display_name(field)
    operator_name = self.class.operator_display(field, operator)
    "#{field_name} #{operator_name} \"#{value}\""
  end

  def to_jsonlogic
    return {} unless valid?

    filter_config = FILTER_TYPES[field]
    operator_config = filter_config[:operators][operator]
    operator_config[:jsonlogic].call(value)
  end


  private

  def operator_valid_for_field
    return unless field.present?

    valid_operators = self.class.operators_for_field(field)
    unless valid_operators.include?(operator)
      errors.add(:operator, "is not valid for #{field}")
    end
  end
end
