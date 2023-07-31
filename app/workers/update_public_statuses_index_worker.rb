# frozen_string_literal: true

class AddToPublicStatusIndexWorker
  include Sidekiq::Worker

  def perform(account_id)
    account = Account.find(account_id)
    return unless account&.discoverable?

    account.add_to_public_statuses_index!
  end
end

class RemoveFromPublicStatusesIndexWorker
  include Sidekiq::Worker

  def perform(account_id)
    account = Account.find(account_id)
    return unless account&.undiscoverable?

    account.remove_from_public_statuses_index!
  end
end
