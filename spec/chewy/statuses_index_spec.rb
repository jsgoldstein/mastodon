# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'with mock elasticsearch response' do
  before do
    mock_elasticsearch_response(described_class, raw_response)
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
end

RSpec.describe 'Chewy indexes', type: :model do
  describe StatusesIndex do
    include_context 'with mock elasticsearch response'

    it 'has settings defined' do
      expect(described_class).to respond_to(:settings)
      expect(described_class.settings).to be_a(Chewy::Index::Settings)
    end

    it 'returns results from a query' do
      results = described_class.query(match: { name: 'status' })
      expect(results).to eq []
    end
  end

  describe PublicStatusesIndex do
    include_context 'with mock elasticsearch response'

    it 'has settings defined' do
      expect(described_class).to respond_to(:settings)
      expect(described_class.settings).to be_a(Chewy::Index::Settings)
    end

    it 'returns results from a query' do
      results = described_class.query(match: { name: 'status' })
      expect(results).to eq []
    end
  end
end
