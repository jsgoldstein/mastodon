# frozen_string_literal: true

class SearchQueryTransformer < Parslet::Transform
  class Query
    attr_reader :should_clauses, :must_not_clauses, :must_clauses, :filter_clauses

    def initialize(clauses)
      grouped = clauses.chunk(&:operator).to_h
      @should_clauses = grouped.fetch(:should, [])
      @must_not_clauses = grouped.fetch(:must_not, [])
      @must_clauses = grouped.fetch(:must, [])
      @filter_clauses = grouped.fetch(:filter, [])
    end

    def apply(query)
      query[:bool] ||= {}

      if should_clauses.present?
        query[:bool][:should] ||= []

        query[:bool][:should] += should_clauses.map { |clause| clause_to_query(clause) }
        query[:bool][:minimum_should_match] = 1
      end

      if must_clauses.present?
        query[:bool][:must] ||= []

        query[:bool][:must] += must_clauses.map { |clause| clause_to_query(clause) }
      end

      if must_not_clauses.present?
        query[:bool][:must_not] ||= []

        query[:bool][:must_not] += must_not_clauses.map { |clause| clause_to_query(clause) }
      end

      if filter_clauses.present?
        query[:bool][:filter] ||= []
        query[:bool][:filter] += filter_clauses.map { |clause| clause_to_filter(clause) }
      end

      query
    end

    private

    def clause_to_query(clause)
      case clause
      when TermClause
        { multi_match: { type: 'most_fields', query: clause.term, fields: ['text', 'text.stemmed'] } }
      when PhraseClause
        { match_phrase: { text: { query: clause.phrase } } }
      else
        raise "Unexpected clause type: #{clause}"
      end
    end

    def clause_to_filter(clause)
      case clause
      when PrefixClause
        { term: { clause.filter => clause.term } }
      else
        raise "Unexpected clause type: #{clause}"
      end
    end
  end

  class Operator
    class << self
      def symbol(str)
        case str
        when '+'
          :must
        when '-'
          :must_not
        when nil
          :should
        else
          raise "Unknown operator: #{str}"
        end
      end
    end
  end

  class TermClause
    attr_reader :prefix, :operator, :term

    def initialize(prefix, operator, term)
      @prefix = prefix
      @operator = Operator.symbol(operator)
      @term = term
    end
  end

  class PhraseClause
    attr_reader :prefix, :operator, :phrase

    def initialize(prefix, operator, phrase)
      @prefix = prefix
      @operator = Operator.symbol(operator)
      @phrase = phrase
    end
  end

  class PrefixClause
    attr_reader :filter, :operator, :term

    def initialize(prefix, term)
      @operator = :filter
      case prefix
      when 'from'
        @filter = :account_id

        username, domain = term.gsub(/\A@/, '').split('@')
        domain           = nil if TagManager.instance.local_domain?(domain)
        account          = Account.find_remote!(username, domain)

        @term = account.id
      else
        raise Mastodon::SyntaxError
      end
    end
  end

  rule(clause: subtree(:clause)) do
    prefix   = clause[:prefix][:term].to_s if clause[:prefix]
    operator = clause[:operator]&.to_s

    if clause[:prefix]
      PrefixClause.new(prefix, clause[:term].to_s)
    elsif clause[:term]
      TermClause.new(prefix, operator, clause[:term].to_s)
    elsif clause[:shortcode]
      TermClause.new(prefix, operator, ":#{clause[:term]}:")
    elsif clause[:phrase]
      PhraseClause.new(prefix, operator, clause[:phrase].is_a?(Array) ? clause[:phrase].map { |p| p[:term].to_s }.join(' ') : clause[:phrase].to_s)
    else
      raise "Unexpected clause type: #{clause}"
    end
  end

  rule(query: sequence(:clauses)) { Query.new(clauses) }
end
