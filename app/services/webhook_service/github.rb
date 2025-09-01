require 'net/http'
require 'uri'
require 'json'

module WebhookService
  class Github < Base
    GITHUB_API = "https://api.github.com"

    def create_webhook
      owner, repo = repo_url.split("/").last(2)
      uri = URI("#{GITHUB_API}/repos/#{owner}/#{repo}/hooks")

      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "token #{access_token}"
      req["Accept"] = "application/vnd.github.v3+json"
      github_secret = secret
      req.body = {
        name: "web",
        active: true,
        events: events,
        config: {
          url: callback_url,
          content_type: "json",
          secret: github_secret,
        }
      }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      data = JSON.parse(res.body)
      {
        id: data["id"],
        secret: github_secret,
        response: data
      }
    end

    def update_webhook(webhook_id, active:)
      owner, repo = repo_url.split("/").last(2)
      uri = URI("#{GITHUB_API}/repos/#{owner}/#{repo}/hooks/#{webhook_id}")

      req = Net::HTTP::Patch.new(uri)
      req["Authorization"] = "token #{access_token}"
      req["Accept"] = "application/vnd.github.v3+json"

      req.body = { active: active }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      JSON.parse(res.body)
    end

    def activate_webhook(webhook_id)
      update_webhook(webhook_id, active: true)
    end

    def deactivate_webhook(webhook_id)
      update_webhook(webhook_id, active: false)
    end
  end
end
