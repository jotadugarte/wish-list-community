# frozen_string_literal: true

# Public Activity Link: safe OG/preview for guests; board redirect when logged-in participant.
# Traceability: [REQ-ACT-001], [REQ-WISH-001], [REQ-BLOCK-001]
class ActivityLinksController < ApplicationController
  include WebAuthentication

  # [REQ-ACT-001] Guest preview never leaks roster; participants land on the member board.
  def show
    activity = find_activity!
    if logged_in?
      render_logged_in_activity_link!(activity)
    else
      @activity = activity
      @return_to = activity_link_path(share_token: activity.share_token)
      @og_title = I18n.t("activities.invitation_title", name: activity.name)
      render :show_guest
    end
  end

  private

  def render_logged_in_activity_link!(activity)
    # [REQ-BLOCK-001] Blocked viewers must not learn the activity identity via the token.
    if UserBlock.blocked_between?(current_user, activity.creator)
      raise ActiveRecord::RecordNotFound
    end

    policy = ActivityPolicy.new(current_user, activity)
    if policy.show? && accepted_participant?(activity)
      redirect_to member_activity_path(activity)
      return
    end

    invite = activity.participants.find_by(user_id: current_user.id, status: "invited")
    if invite.present? && policy.join?
      @activity = activity
      @og_title = I18n.t("activities.invitation_title", name: activity.name)
      render :show_invitee
      return
    end

    @activity = activity
    @return_to = activity_link_path(share_token: activity.share_token)
    @og_title = I18n.t("activities.invitation_title", name: activity.name)
    render :show_guest
  end

  def accepted_participant?(activity)
    activity.participants.where(user_id: current_user.id, status: "accepted").exists? ||
      current_user.id == activity.creator_id
  end

  def find_activity!
    token = ActivityLinkToken.new(params[:share_token])
    activity = Activity.find_by(share_token: token.value)
    raise ActiveRecord::RecordNotFound if activity.nil? || activity.cancelled?

    activity
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end
end
