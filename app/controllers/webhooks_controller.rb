class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    result = WebhookReceiverService.call(request)
    if result[:status] == :error || result[:status] == :unauthorized
      render json: result, status: :unauthorized
    else
      TicketUpdateService.call(result)
      render json: { status: "ok" }
    end
  end
end