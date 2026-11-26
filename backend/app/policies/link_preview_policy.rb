# frozen_string_literal: true

# Authenticated users may request best-effort OpenGraph previews.
# Traceability: [REQ-ITEM-006]
class LinkPreviewPolicy < ApplicationPolicy
  # [REQ-ITEM-006] Any active authenticated user may preview a store URL.
  def create?
    user.present? && !user.discarded?
  end
end
