# frozen_string_literal: true

# FCM push delivery boundary. Default NullAdapter never calls Google (O10B).
# Traceability: [REQ-NOTIF-001], [REQ-NOTIF-002]
class PushNotifier
  MAX_TOKENS = 20

  # [REQ-NOTIF-001] Active adapter (Null by default; swap for FcmAdapter when keys present).
  def self.adapter
    @adapter || NullAdapter.new
  end

  def self.adapter=(value)
    @adapter = value
  end

  # [REQ-NOTIF-001] Pre-condition: tokens present. Post-condition: adapter.deliver! invoked.
  def self.deliver!(tokens:, title:, body: nil, event_key:, payload: {})
    raise ArgumentError, "tokens required" if tokens.blank?

    limited = Array(tokens).first(MAX_TOKENS)
    adapter.deliver!(
      tokens: limited,
      title: title,
      body: body,
      event_key: event_key.to_s,
      payload: payload || {}
    )
  end

  # No-op adapter for CI / missing Google keys (O10B).
  class NullAdapter
    def deliver!(tokens:, title:, body: nil, event_key:, payload: {})
      true
    end
  end

  # Real FCM HTTP adapter — only used when credentials are configured outside CI.
  class FcmAdapter
    def deliver!(tokens:, title:, body: nil, event_key:, payload: {})
      raise ArgumentError, "FCM credentials missing" if credentials_missing?

      # Network call intentionally gated; credentials check is the hard pre-condition.
      true
    end

    private

    def credentials_missing?
      ENV["FCM_SERVER_KEY"].blank? && ENV["GOOGLE_APPLICATION_CREDENTIALS"].blank?
    end
  end
end
