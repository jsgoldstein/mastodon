# frozen_string_literal: true

class StatusSearchService < BaseService
  def call(query, account = nil, options = {})
    @query   = query&.strip
    @account = account
    @options = options
    @limit   = options[:limit].to_i
    @offset  = options[:offset].to_i

    status_search_results
  end

  private

  def status_search_results
    base_query = StatusesIndex.query(
      bool: {
        should: [
          {
            bool: {
              must: {
                term: { publicly_searchable: false }
              },
              filter: {
                term: { searchable_by: @account.id }
              }
            }
          },
          {
            bool: {
              must: {
                term: { publicly_searchable: true }
              }
            }
          }
        ]
      }
    )
    definition = parsed_query.apply(base_query)

    definition = definition.filter(term: { account_id: @options[:account_id] }) if @options[:account_id].present?

    if @options[:min_id].present? || @options[:max_id].present?
        range      = {}
        range[:gt] = @options[:min_id].to_i if @options[:min_id].present?
        range[:lt] = @options[:max_id].to_i if @options[:max_id].present?
        definition = definition.filter(range: { id: range })
    end

    results             = definition.limit(@limit).offset(@offset).objects.compact
    account_ids         = results.map(&:account_id)
    account_domains     = results.map(&:account_domain)
    preloaded_relations = @account.relations_map(account_ids, account_domains)

    results.reject { |status| StatusFilter.new(status, @account, preloaded_relations).filtered? }
  rescue Faraday::ConnectionFailed, Parslet::ParseFailed
    []
  end

  def parsed_query
    SearchQueryTransformer.new.apply(SearchQueryParser.new.parse(@query))
  end
end
