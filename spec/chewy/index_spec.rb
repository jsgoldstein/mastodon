# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Chewy indexes', type: :model do
  Chewy::Index.descendants.each do |index_class|
    describe index_class do
      it 'has settings defined' do
        expect(index_class).to respond_to(:settings)
        expect(index_class.settings).to be_a(Chewy::Index::Settings)

        expect(index_class.settings[:index]).to have_key(:refresh_interval)
      end
    end
  end
end
