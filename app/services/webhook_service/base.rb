require "securerandom"
module WebhookService
  class Base
    attr_reader :repo_url, :access_token, :callback_url, :events

    def initialize(repo_url:, access_token:, callback_url:, events: [])
      @repo_url = repo_url
      @access_token = access_token
      @callback_url = callback_url
      @events = events.presence || default_events
    end

    def create_webhook
      raise NotImplementedError, "Subclasses must implement"
    end

    def secret
      SecureRandom.hex(20)
    end

    def default_events
      ["push", "pull_request"]
    end
  end
end
