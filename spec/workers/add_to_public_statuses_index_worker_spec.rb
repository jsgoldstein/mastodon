# frozen_string_literal: true

require 'rails_helper'

describe AddToPublicStatusesIndexWorker do
  describe '#perform' do
    let(:account) { Fabricate(:account, discoverable: discoverable) }
    let(:account_id) { account.id }

    context 'when account is discoverable' do
      let(:discoverable) { true }

      it 'adds the account to the public statuses index' do
        allow(Account).to receive(:find_by_id).with(account_id).and_return(account)
        expect(account).to receive(:add_to_public_statuses_index!)
        subject.perform(account_id)
      end
    end

    context 'when account is undiscoverable' do
      let(:discoverable) { false }

      it 'does not add the account to public statuses index' do
        allow(Account).to receive(:find_by_id).with(account_id).and_return(account)
        expect(account).not_to receive(:add_to_public_statuses_index!)
        subject.perform(account_id)
      end
    end

    context 'when account does not exist' do
      let(:account_id) { 999 }

      it 'does not raise an error' do
        expect { subject.perform(account_id) }.not_to raise_error
      end
    end
  end
end
