module WebhookService
  class Bitbucket < Base
    BITBUCKET_API = "https://api.bitbucket.org/2.0"

    def create_webhook
      owner, repo = repo_url.split("/").last(2)

      uri = URI("#{BITBUCKET_API}/repositories/#{owner}/#{repo}/hooks")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{access_token}"
      req["Content-Type"] = "application/json"

      secret = SecureRandom.hex(20)

      req.body = {
        description: "Redmine Git Connector",
        url: callback_url,
        active: true,
        events: events,
        secret: secret
      }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      data = JSON.parse(res.body)

      {
        id: data["uuid"],
        secret: secret,
        response: data
      }
    end

    def update_webhook(webhook_id, active:)
      owner, repo = repo_url.split("/").last(2)
      uri = URI("#{BITBUCKET_API}/repositories/#{owner}/#{repo}/hooks/#{webhook_id}")

      req = Net::HTTP::Put.new(uri)
      req["Authorization"] = "Bearer #{access_token}"
      req["Content-Type"] = "application/json"
      req.body = { active: active }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      JSON.parse(res.body)
    end

    alias activate_webhook update_webhook
    alias deactivate_webhook update_webhook
  end
end