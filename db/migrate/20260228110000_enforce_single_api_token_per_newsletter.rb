class EnforceSingleApiTokenPerNewsletter < ActiveRecord::Migration[8.1]
  def up
    deduplicate_api_tokens
  end

  def down; end

  private

  def deduplicate_api_tokens
    execute <<~SQL
      DELETE FROM api_tokens
      WHERE id IN (
        SELECT id
        FROM (
          SELECT
            id,
            ROW_NUMBER() OVER (PARTITION BY newsletter_id ORDER BY id ASC) AS row_number
          FROM api_tokens
        ) duplicates
        WHERE duplicates.row_number > 1
      )
    SQL
  end
end
