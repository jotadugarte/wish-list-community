# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Admin provisioning (REQ-ADM-001 / O6A): there is no in-app promote UI.
# Promote/demote via seed or rails console, e.g.:
#   User.find_by!(email_address: "ops@example.com").update!(role: "admin")
#   User.find_by!(email_address: "ops@example.com").update!(role: "user")
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
