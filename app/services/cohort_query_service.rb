class CohortQueryService
  def initialize(cohort)
    @cohort = cohort
    @newsletter = cohort.newsletter
  end

  def call
    base_scope = @newsletter.subscribers.verified

    return base_scope unless @cohort.has_filters?

    # Convert the FilterGroup to JSONLogic, then translate to SQL
    jsonlogic_rule = @cohort.filter_group.to_jsonlogic
    return base_scope if jsonlogic_rule.blank?

    arel_condition = JsonLogicSqlTranslator.translate(jsonlogic_rule)
    return base_scope if arel_condition.blank?

    base_scope.where(arel_condition)
  end

  def count
    call.count
  end
end
