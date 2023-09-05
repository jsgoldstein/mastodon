# frozen_string_literal: true

require 'rails_helper'

describe AccountStatusesSearch do
  before do
    allow(Chewy).to receive(:enabled?).and_return(true)
  end

  describe 'a non-indexable account becoming indexable' do
    let(:account) { Account.find_by(indexable: false) }

    context 'when picking a non-indexable account' do
      it 'has no statuses in the PublicStatusesIndex' do
        expect(PublicStatusesIndex.filter(term: { account_id: account.id }).count).to eq(0)
      end

      it 'has statuses in the StatusesIndex' do
        expect(StatusesIndex.filter(term: { account_id: account.id }).count).to eq(account.statuses.count)
      end
    end

    context 'when the non-indexable account becomes indexable' do
      it 'adds the public statuses to the PublicStatusesIndex' do
        account.indexable = true
        account.save!
        expect(PublicStatusesIndex.filter(term: { account_id: account.id }).count).to eq(account.statuses.where(visibility: :public).count)
        expect(StatusesIndex.filter(term: { account_id: account.id }).count).to eq(account.statuses.count)
      end
    end
  end

  describe 'an indexable account becoming non-indexable' do
    let(:account) { Account.find_by(indexable: true) }

    context 'when picking an indexable account' do
      it 'has statuses in the PublicStatusesIndex' do
        expect(PublicStatusesIndex.filter(term: { account_id: account.id }).count).to eq(account.statuses.where(visibility: :public).count)
      end

      it 'has statuses in the StatusesIndex' do
        expect(StatusesIndex.filter(term: { account_id: account.id }).count).to eq(account.statuses.count)
      end
    end

    context 'when the indexable account becomes non-indexable' do
      it 'removes the statuses from the PublicStatusesIndex' do
        account.indexable = false
        account.save!
        expect(PublicStatusesIndex.filter(term: { account_id: account.id }).count).to eq(0)
        expect(StatusesIndex.filter(term: { account_id: account.id }).count).to eq(account.statuses.count)
      end
    end
  end
end
