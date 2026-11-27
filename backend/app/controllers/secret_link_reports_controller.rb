# frozen_string_literal: true

# Hotwire wishlist abuse report from authenticated Secret Link (O3A).
# Traceability: [REQ-DISC-001], [REQ-WISH-002], [REQ-AUTH-001], [REQ-ADM-001]
class SecretLinkReportsController < ApplicationController
  include WebAuthentication
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  rate_limit to: 20, within: 3.minutes, only: :create, name: "secret_link_report_create",
                by: -> { current_user&.id || request.remote_ip }, with: -> {
    redirect_back fallback_location: root_path, alert: I18n.t("api.v1.errors.rate_limited"),
                  status: :see_other
  }

  before_action :require_login!

  # [REQ-DISC-001] [REQ-ADM-001] Creates a pending Wishlist report for a non-owner viewer.
  def create
    wishlist = find_shared_wishlist!
    register_share_if_needed!(wishlist)
    candidate = Report.new(reporter: current_user, reportable: wishlist)
    authorize candidate, :create?

    Report.submit!(
      reporter: current_user,
      reportable: wishlist,
      reason: params[:reason],
      details: params[:details]
    )
    redirect_to secret_link_path(share_token: wishlist.share_token),
                notice: I18n.t("secret_links.report_submitted")
  rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to secret_link_path(share_token: params[:share_token]),
                alert: I18n.t("api.v1.errors.report_invalid")
  end

  private

  def find_shared_wishlist!
    token_vo = ShareToken.new(params[:share_token])
    wishlist = Wishlist.kept.find_by(share_token: token_vo.value, privacy_mode: "shared")
    raise ActiveRecord::RecordNotFound if wishlist.nil?
    raise ActiveRecord::RecordNotFound if wishlist.owner.discarded?
    if UserBlock.blocked_between?(current_user, wishlist.owner)
      raise ActiveRecord::RecordNotFound
    end

    wishlist
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  def register_share_if_needed!(wishlist)
    return if current_user.id == wishlist.owner_id

    WishlistShare.upsert_secret_link!(wishlist: wishlist, user: current_user)
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  def require_login!
    return if logged_in?

    redirect_to new_session_path(return_to: secret_link_path(share_token: params[:share_token])),
                alert: t("secret_links.login_required", default: "Log in")
  end

  def render_not_found
    head :not_found
  end
end
