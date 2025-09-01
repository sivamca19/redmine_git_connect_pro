module WebhookService
  class Gitlab < Base
    GITLAB_API = "https://gitlab.com/api/v4"

    def create_webhook
      project_id = repo_url.split("/").last(2).join("/") # namespace/repo

      uri = URI("#{GITLAB_API}/projects/#{CGI.escape(project_id)}/hooks")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{access_token}"
      req["Content-Type"] = "application/json"

      req.body = {
        url: callback_url,
        push_events: true,
        merge_requests_events: true,
        enable_ssl_verification: true,
        token: SecureRandom.hex(20) # secret
      }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      data = JSON.parse(res.body)

      {
        id: data["id"],
        secret: req.body[:token],
        response: data
      }
    end

    def update_webhook(webhook_id, active:)
      project_id = repo_url.split("/").last(2).join("/")
      uri = URI("#{GITLAB_API}/projects/#{CGI.escape(project_id)}/hooks/#{webhook_id}")

      req = Net::HTTP::Put.new(uri)
      req["Authorization"] = "Bearer #{access_token}"
      req["Content-Type"] = "application/json"

      req.body = { enable_ssl_verification: active }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      JSON.parse(res.body)
    end

    alias activate_webhook update_webhook
    alias deactivate_webhook update_webhook
  end
end