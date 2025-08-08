# Translates JSONLogic rules to SQL WHERE conditions for PostgreSQL queries.
#
# This class converts JSONLogic expressions into SQL conditions that can be used
# with ActiveRecord queries. It focuses on subscriber label filtering for cohort
# management in newsletter applications.
#
# @example Basic usage
#   rule = {"in": ["premium", {"var": "labels"}]}
#   sql = JsonLogicSqlTranslator.translate(rule)
#   # Returns: "'premium' = ANY(labels)"
#
# @example Complex conditions
#   rule = {"and": [
#     {"in": ["premium", {"var": "labels"}]},
#     {"!": {"in": ["inactive", {"var": "labels"}]}}
#   ]}
#   sql = JsonLogicSqlTranslator.translate(rule)
#   # Returns: "('premium' = ANY(labels) AND NOT 'inactive' = ANY(labels))"
#
# @see https://jsonlogic.com/ JSONLogic specification
class JsonLogicSqlTranslator
  # Translates a JSONLogic rule to a SQL WHERE condition.
  #
  # @param rule [Hash] The JSONLogic rule to translate
  # @return [String, nil] SQL WHERE condition or nil if rule is invalid
  #
  # @example
  #   JsonLogicSqlTranslator.translate({"in": ["admin", {"var": "labels"}]})
  #   # => "'admin' = ANY(labels)"
  def self.translate(rule)
    new(rule).translate
  end

  # Initialize with a JSONLogic rule.
  #
  # @param rule [Hash] The JSONLogic rule to translate
  def initialize(rule)
    @rule = rule
  end

  # Translates the rule to SQL.
  #
  # @return [String, nil] SQL WHERE condition or nil if rule is blank
  def translate
    return nil if @rule.blank?

    translate_rule(@rule)
  end

  private

  # Recursively translates JSONLogic rules to Arel nodes.
  #
  # Supported operators:
  # - "and": Logical AND - all conditions must be true
  # - "or": Logical OR - any condition must be true
  # - "!": Logical NOT - negates the condition
  # - "in": Array membership - checks if value exists in PostgreSQL array
  # - "==": Equality - checks if arrays are exactly equal
  # - "!=": Inequality - checks if arrays are not equal
  #
  # @param rule [Hash] JSONLogic rule to translate
  # @return [Arel::Nodes::Node, nil] Arel node or nil if invalid
  def translate_rule(rule)
    case rule
    when Hash
      operator = rule.keys.first
      values = rule.values.first

      case operator
      when "and"
        # Logical AND: all conditions must be true
        # Example: {"and": [condition1, condition2]}
        conditions = values.map { |v| translate_rule(v) }.compact
        return nil if conditions.empty?
        conditions.reduce { |acc, condition| acc.and(condition) }

      when "or"
        # Logical OR: any condition must be true
        # Example: {"or": [condition1, condition2]}
        conditions = values.map { |v| translate_rule(v) }.compact
        return nil if conditions.empty?
        conditions.reduce { |acc, condition| acc.or(condition) }

      when "!"
        # Logical NOT: negates the condition
        # Example: {"!": condition}
        condition = translate_rule(values)
        return nil if condition.blank?
        condition.not

      when "in"
        # Array membership check using PostgreSQL ANY operator
        # Format: {"in": ["label_name", {"var": "labels"}]}
        # Translates to: 'label_name' = ANY(labels)
        return nil if values.nil? || values.length < 2

        label_name = values[0]
        var_ref = values[1]

        if var_ref.is_a?(Hash) && var_ref["var"] == "labels"
          table = Arel::Table.new(:subscribers)
          any_function = Arel::Nodes::NamedFunction.new("ANY", [ table[:labels] ])
          Arel::Nodes.build_quoted(label_name).eq(any_function)
        end

      when "=="
        # Equality check for entire array
        # Format: {"==": [{"var": "labels"}, ["admin", "premium"]]}
        # Translates to: labels = '["admin","premium"]'
        return nil if values.nil? || values.length < 2

        left = values[0]
        right = values[1]

        if left.is_a?(Hash) && left["var"] == "labels"
          table = Arel::Table.new(:subscribers)
          table[:labels].eq(Arel::Nodes.build_quoted(Array(right).to_json))
        end

      when "!="
        # Inequality check for entire array
        # Format: {"!=": [{"var": "labels"}, ["admin", "premium"]]}
        # Translates to: labels != '["admin","premium"]'
        return nil if values.nil? || values.length < 2

        left = values[0]
        right = values[1]

        if left.is_a?(Hash) && left["var"] == "labels"
          table = Arel::Table.new(:subscribers)
          table[:labels].not_eq(Arel::Nodes.build_quoted(Array(right).to_json))
        end
      end
    end
  end
end
