# frozen_string_literal: true

require 'rails_helper'

describe SearchQueryTransformer do
  describe 'initialization' do
    let(:parser) { SearchQueryParser.new.parse('query') }

    it 'sets attributes' do
      transformer = described_class.new.apply(parser)

      expect(transformer.should_clauses.first).to be_a(SearchQueryTransformer::TermClause)
      expect(transformer.must_clauses.first).to be_nil
      expect(transformer.must_not_clauses.first).to be_nil
      expect(transformer.filter_clauses.first).to be_nil
    end
  end

  describe '#apply' do
    subject(:applied_query) do
      described_class.new.apply(
        SearchQueryParser.new.parse(search_term)
      ).apply(query)
    end

    let(:query) { { bool: {} } }
    let(:search_term) { '' }

    context 'when query is just a bool' do
      it 'returns a hash of bool' do
        expect(applied_query).to eq({ query })
      end
    end

    context 'when should_clauses are present' do
      let(:search_term) { 'test' }

      it 'adds should clauses to the query' do
        expect(applied_query[:bool][:should]).length eq(1)
        expect(applied_query[:bool][:should][:multi_match][:query]).length eq(search_term)
      end

      it 'sets minimum_should_match to 1' do
        expect(applied_query[:minimum_should_match]).to eq(1)
      end
    end

    context 'when must_clauses are present' do
      let(:search_term) { '+test' }

      it 'adds must clauses to the query' do
        expect(applied_query[:bool][:must]).length eq(1)
        expect(applied_query[:bool][:must][:multi_match][:query]).length eq(search_term)
      end
    end

    context 'when must_not_clauses are present' do
      let(:search_term) { '-test' }

      it 'adds must_not clauses to the query' do
        expect(applied_query[:bool][:must_not]).length eq(1)
        expect(applied_query[:bool][:must_not][:multi_match][:query]).length eq(search_term)
      end
    end

    context 'when filter_clauses are present' do
      let(:search_term) { 'from:test_account' }
      let(:account) { Fabricate(:test_account) }

      it 'adds filter clauses to the query' do
        expect(applied_query[:bool][:filter]).length eq(1)
        expect(applied_query[:bool][:filter][:term][:account_id]).length eq(account.id)
      end
    end
  end
end
