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
        expect(applied_query).to eq(query)
      end
    end

    context 'when should_clauses are present' do
      let(:search_term) { 'test' }

      it 'adds should clauses to the query' do
        expect(applied_query[:bool][:should].length).to eq(1)
        expect(applied_query[:bool][:should][0][:multi_match][:query]).to eq(search_term)
      end

      it 'sets minimum_should_match to 1' do
        expect(applied_query[:bool][:minimum_should_match]).to eq(1)
      end
    end

    context 'when must_clauses are present' do
      let(:search_term) { '+test' }

      it 'adds must clauses to the query' do
        expect(applied_query[:bool][:must].length).to eq(1)
        expect(applied_query[:bool][:must][0][:multi_match][:query]).to eq(search_term[1..-1])
      end
    end

    context 'when must_not_clauses are present' do
      let(:search_term) { '-test' }

      it 'adds must_not clauses to the query' do
        expect(applied_query[:bool][:must_not].length).to eq(1)
        expect(applied_query[:bool][:must_not][0][:multi_match][:query]).to eq(search_term[1..-1])
      end
    end

    context 'when filter_clauses are present' do
      let(:search_term) { 'from:test_account' }
      let(:account) { Fabricate(:test_account) }

      it 'adds filter clauses to the query' do
        expect(applied_query[:bool][:filter].length).to eq(1)
        expect(applied_query[:bool][:filter][0][:term][:account_id]).to eq(account.id)
      end
    end

    context 'when all clause lists are present' do
      let(:should) { 'should' }
      let(:must) { '+must' }
      let(:must_not) { '-nope' }
      let(:filter) { 'from:test_account' }
      let(:search_term) { should + ' ' + must + ' ' + must_not + ' ' + filter }
      let(:account) { Fabricate(:test_account) }

      it 'adds all clauses to the query' do
        expect(applied_query[:bool][:should][0][:multi_match][:query]).to eq(should)
        expect(applied_query[:bool][:must][0][:multi_match][:query]).to eq(must[1..-1])
        expect(applied_query[:bool][:must_not][0][:multi_match][:query]).to eq(must_not[1..-1])
        expect(applied_query[:bool][:filter][0][:term][:account_id]).to eq(account.id)
      end
    end
  end
end
