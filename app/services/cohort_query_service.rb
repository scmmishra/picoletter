class CohortQueryService
  def initialize(cohort)
    @cohort = cohort
    @newsletter = cohort.newsletter
  end

  def call
    base_scope = @newsletter.subscribers.verified

    return base_scope if @cohort.filter_conditions.blank?

    arel_condition = JsonLogicSqlTranslator.translate(@cohort.filter_conditions)
    return base_scope if arel_condition.blank?

    base_scope.where(arel_condition)
  end

  def count
    call.count
  end
end
