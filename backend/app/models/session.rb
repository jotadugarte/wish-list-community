# frozen_string_literal: true

# Stateful Web Cookie Session model.
# Traceability: [REQ-AUTH-001]
class Session < ApplicationRecord
  belongs_to :user
end
