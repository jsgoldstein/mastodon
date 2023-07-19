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
        SearchQueryParser.new.parse('query')
      ).apply(query)
    end

    let(:query) { { bool: {} } }
    let(:search_string) { 'search string' }
    let(:term) { { term: { field_name: search_string } } }

    context 'when query is just a bool' do
      it 'does not modify the query' do
        expect(applied_query).to eq(query)
      end
    end

    context 'when should_clauses are present' do
      let(:should) { { bool: { should: [term] } } }

      it 'adds should clauses to the query' do
        expect(applied_query[:bool][:should]).to include(term)
      end

      it 'sets minimum_should_match to 1' do
        expect(applied_query[:minimum_should_match]).to eq(1)
      end
    end

    context 'when must_clauses are present' do
      let(:must) { { bool: { must: [term] } } }

      it 'adds must clauses to the query' do
        expect(applied_query[:bool][:must]).to include(term)
      end
    end

    context 'when must_not_clauses are present' do
      let(:must_not) { { bool: { must_not: [term] } } }

      it 'adds must_not clauses to the query' do
        expect(applied_query[:bool][:must_not]).to include(term)
      end
    end

    context 'when filter_clauses are present' do
      let(:filter) { { bool: { filter: [term] } } }

      it 'adds filter clauses to the query' do
        expect(applied_query[:bool][:filter]).to include(term)
      end
    end
  end
end
