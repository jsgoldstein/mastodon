# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicStatusesIndex do
  describe 'Searching the index' do
    before do
      mock_elasticsearch_response(described_class, raw_response)
    end

    it 'returns results from a query' do
      results = described_class.query(match: { name: 'status' })

      expect(results).to eq([])
    end
  end

  def raw_response
    {
      took: 3,
      hits: {
        hits: [
          {
            _id: '0',
            _score: 1.6375021,
          },
        ],
      },
    }
  end

  it 'has settings defined' do
    expect(described_class).to respond_to(:settings)
    expect(described_class.settings).to be_a(Chewy::Index::Settings)
  end

  it 'returns results from a query' do
    results = described_class.query(match: { name: 'status' })
    expect(results).to eq([])
  end
end
