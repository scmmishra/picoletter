module Newsletters::PostsHelper
  def cohort_options_for_select(cohorts, selected_cohort_id = nil)
    options = cohorts.map do |cohort|
      count = cohort.subscriber_count
      text = "#{cohort.name} (#{count} subscribers)"
      [ text, cohort.id ]
    end

    options_for_select(options, selected_cohort_id)
  end
end
