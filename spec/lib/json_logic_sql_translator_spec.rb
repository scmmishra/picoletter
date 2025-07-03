require 'rails_helper'

RSpec.describe JsonLogicSqlTranslator do
  describe '.translate' do
    it 'returns nil for blank rules' do
      expect(described_class.translate(nil)).to be_nil
      expect(described_class.translate({})).to be_nil
      expect(described_class.translate('')).to be_nil
    end

    context 'with "in" operator' do
      it 'translates label membership check' do
        rule = { "in" => [ "premium", { "var" => "labels" } ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::Equality)
        expect(result.to_sql).to include("ANY(\"subscribers\".\"labels\") = 'premium'")
      end

      it 'returns nil for invalid variable reference' do
        rule = { "in" => [ "premium", { "var" => "other_field" } ] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end

      it 'returns nil for malformed in clause' do
        rule = { "in" => [ "premium" ] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end
    end

    context 'with "==" operator' do
      it 'translates exact array equality' do
        rule = { "==" => [ { "var" => "labels" }, [ "admin", "premium" ] ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::Equality)
        expect(result.to_sql).to include("\"subscribers\".\"labels\" = '[\"admin\",\"premium\"]'")
      end

      it 'handles single value arrays' do
        rule = { "==" => [ { "var" => "labels" }, "admin" ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::Equality)
        expect(result.to_sql).to include("\"subscribers\".\"labels\" = '[\"admin\"]'")
      end

      it 'returns nil for invalid variable reference' do
        rule = { "==" => [ { "var" => "other_field" }, [ "admin" ] ] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end
    end

    context 'with "!=" operator' do
      it 'translates array inequality' do
        rule = { "!=" => [ { "var" => "labels" }, [ "admin", "premium" ] ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::NotEqual)
        expect(result.to_sql).to include("\"subscribers\".\"labels\" != '[\"admin\",\"premium\"]'")
      end

      it 'returns nil for invalid variable reference' do
        rule = { "!=" => [ { "var" => "other_field" }, [ "admin" ] ] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end
    end

    context 'with "and" operator' do
      it 'translates logical AND conditions' do
        rule = { "and" => [
          { "in" => [ "premium", { "var" => "labels" } ] },
          { "in" => [ "active", { "var" => "labels" } ] }
        ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::And)
        sql = result.to_sql
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'premium'")
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'active'")
        expect(sql).to include(" AND ")
      end

      it 'returns nil for empty conditions' do
        rule = { "and" => [] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end

      it 'filters out nil conditions' do
        rule = { "and" => [
          { "in" => [ "premium", { "var" => "labels" } ] },
          { "in" => [ "invalid", { "var" => "other_field" } ] }  # This will be nil
        ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::Equality)  # Single condition, not AND
        expect(result.to_sql).to include("ANY(\"subscribers\".\"labels\") = 'premium'")
      end
    end

    context 'with "or" operator' do
      it 'translates logical OR conditions' do
        rule = { "or" => [
          { "in" => [ "admin", { "var" => "labels" } ] },
          { "in" => [ "enterprise", { "var" => "labels" } ] }
        ] }
        result = described_class.translate(rule)

        # Result might be wrapped in Grouping node, check the inner OR or the result itself
        expect(result).to satisfy do |node|
          node.is_a?(Arel::Nodes::Or) ||
          (node.is_a?(Arel::Nodes::Grouping) && node.expr.is_a?(Arel::Nodes::Or))
        end

        sql = result.to_sql
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'admin'")
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'enterprise'")
        expect(sql).to include(" OR ")
      end

      it 'returns nil for empty conditions' do
        rule = { "or" => [] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end
    end

    context 'with "!" operator' do
      it 'translates logical NOT conditions' do
        rule = { "!" => { "in" => [ "inactive", { "var" => "labels" } ] } }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::Not)
        expect(result.to_sql).to include("NOT (ANY(\"subscribers\".\"labels\") = 'inactive')")
      end

      it 'returns nil for nil condition' do
        rule = { "!" => { "in" => [ "invalid", { "var" => "other_field" } ] } }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end
    end

    context 'with complex nested rules' do
      it 'translates complex AND/OR combinations' do
        rule = { "and" => [
          { "or" => [
            { "in" => [ "admin", { "var" => "labels" } ] },
            { "in" => [ "enterprise", { "var" => "labels" } ] }
          ] },
          { "!" => { "in" => [ "inactive", { "var" => "labels" } ] } }
        ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::And)
        sql = result.to_sql
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'admin'")
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'enterprise'")
        expect(sql).to include("NOT (ANY(\"subscribers\".\"labels\") = 'inactive')")
        expect(sql).to include(" OR ")
        expect(sql).to include(" AND ")
      end

      it 'handles deeply nested conditions' do
        rule = { "and" => [
          { "or" => [
            { "in" => [ "premium", { "var" => "labels" } ] },
            { "and" => [
              { "in" => [ "basic", { "var" => "labels" } ] },
              { "in" => [ "verified", { "var" => "labels" } ] }
            ] }
          ] },
          { "!" => { "in" => [ "suspended", { "var" => "labels" } ] } }
        ] }
        result = described_class.translate(rule)

        expect(result).to be_a(Arel::Nodes::And)
        sql = result.to_sql
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'premium'")
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'basic'")
        expect(sql).to include("ANY(\"subscribers\".\"labels\") = 'verified'")
        expect(sql).to include("NOT (ANY(\"subscribers\".\"labels\") = 'suspended')")
      end
    end

    context 'with invalid rules' do
      it 'returns nil for unsupported operators' do
        rule = { "unsupported" => [ "value" ] }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end

      it 'returns nil for non-hash rules' do
        rule = "invalid"
        result = described_class.translate(rule)

        expect(result).to be_nil
      end

      it 'returns nil for rules with missing values' do
        rule = { "in" => nil }
        result = described_class.translate(rule)

        expect(result).to be_nil
      end
    end
  end

  describe '#translate' do
    it 'can be instantiated and called' do
      rule = { "in" => [ "premium", { "var" => "labels" } ] }
      translator = described_class.new(rule)
      result = translator.translate

      expect(result).to be_a(Arel::Nodes::Equality)
      expect(result.to_sql).to include("ANY(\"subscribers\".\"labels\") = 'premium'")
    end
  end
end
