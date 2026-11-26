# frozen_string_literal: true

# Purchase link for an Item; URL validated via ExternalUrl.
# Traceability: [REQ-ITEM-001]
class ItemLink < ApplicationRecord
  belongs_to :item

  validates :url, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :url_must_be_external_http

  # [REQ-ITEM-001] ExternalUrl Value Object for the stored purchase URL.
  def url_vo
    ExternalUrl.new(url)
  end

  # [REQ-ITEM-001] Compact JSON for nested item payloads.
  def as_api_json
    { id: id, url: url, position: position }
  end

  private

  def url_must_be_external_http
    ExternalUrl.new(url)
  rescue ArgumentError => e
    errors.add(:url, e.message)
  end
end
