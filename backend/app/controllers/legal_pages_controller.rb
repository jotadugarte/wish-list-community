# frozen_string_literal: true

# Public bilingual Terms / Privacy pages (placeholder copy until owner approves).
# Traceability: [REQ-AUTH-002] O8A / O13A
class LegalPagesController < ApplicationController
  def terms
    render :terms, layout: "application"
  end

  def privacy
    render :privacy, layout: "application"
  end
end
