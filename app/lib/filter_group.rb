class FilterGroup
  include ActiveModel::Model
  include ActiveModel::Attributes

  LOGIC_OPERATORS = {
    "and" => "All conditions must be true",
    "or" => "Any condition must be true"
  }.freeze

  attribute :operator, :string, default: "and"
  attribute :conditions, default: -> { [] }

  validates :operator, inclusion: { in: LOGIC_OPERATORS.keys }

  def self.from_hash(data)
    return new if data.blank? || data == {}

    # Parse JSON string if needed
    if data.is_a?(String)
      begin
        data = JSON.parse(data)
      rescue JSON::ParserError
        return new # Return empty group for invalid JSON
      end
    end
    return new if data.blank? || data == {}

    # Handle both old JSONLogic format and new format
    if data.key?("type") && data["type"] == "group"
      # New format
      group = new(operator: data["operator"])
      group.conditions = (data["conditions"] || []).map do |condition_data|
        if condition_data["type"] == "group"
          FilterGroup.from_hash(condition_data)
        else
          FilterCondition.new(
            field: condition_data["field"],
            operator: condition_data["operator"],
            value: condition_data["value"]
          )
        end
      end
      group
    else
      new # Return empty group for unknown formats
    end
  end

  def to_hash
    {
      "type" => "group",
      "operator" => operator,
      "conditions" => conditions.map do |condition|
        if condition.is_a?(FilterGroup)
          condition.to_hash
        else
          {
            "type" => "condition",
            "field" => condition.field,
            "operator" => condition.operator,
            "value" => condition.value
          }
        end
      end
    }
  end

  def to_jsonlogic
    return {} if conditions.empty?

    jsonlogic_conditions = conditions.map do |condition|
      if condition.is_a?(FilterGroup)
        condition.to_jsonlogic
      else
        condition.to_jsonlogic
      end
    end.reject(&:blank?)

    return {} if jsonlogic_conditions.empty?
    return jsonlogic_conditions.first if jsonlogic_conditions.length == 1

    { operator => jsonlogic_conditions }
  end

  def display_text
    return "No conditions" if conditions.empty?

    condition_texts = conditions.map do |condition|
      if condition.is_a?(FilterGroup)
        "(#{condition.display_text})"
      else
        condition.display_text
      end
    end

    operator_text = LOGIC_OPERATORS[operator] || operator.upcase
    if conditions.length == 1
      condition_texts.first
    else
      condition_texts.join(" #{operator.upcase} ")
    end
  end

  def valid?
    return false if conditions.empty?

    conditions.all? do |condition|
      if condition.is_a?(FilterGroup)
        condition.valid?
      else
        condition.valid?
      end
    end
  end

  def flat_conditions
    # Returns all leaf conditions (non-group conditions) for simple display
    conditions.flat_map do |condition|
      if condition.is_a?(FilterGroup)
        condition.flat_conditions
      else
        [ condition ]
      end
    end
  end
end
