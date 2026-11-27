# frozen_string_literal: true

module Member
  # Member app home — redirects into wishlists shell.
  # Traceability: [REQ-WISH-001] O12A
  class HomeController < BaseController
    def show
      redirect_to member_wishlists_path
    end
  end
end
