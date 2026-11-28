# frozen_string_literal: true

module Member
  # Empty section shells for MemberWebShell nav targets (filled in later steps).
  # Traceability: [REQ-WISH-001] O12A / O2B
  class ShellController < BaseController
    SECTIONS = %w[wishlists shared friends reservations notifications settings].freeze

    def show
      skip_authorization
      @section = params[:section].to_s
      raise ActiveRecord::RecordNotFound unless SECTIONS.include?(@section)

      render "member/shell/show"
    end
  end
end
