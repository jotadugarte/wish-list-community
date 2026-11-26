# frozen_string_literal: true

module Api
  module V1
    # Secret reservation create (nested under items) + extend/cancel member actions.
    # Traceability: [REQ-RES-001], [REQ-RES-004], [REQ-RES-005], [REQ-ARCH-003]
    class ReservationsController < BaseController
      skip_after_action :verify_policy_scoped, only: %i[create update destroy]

      # [REQ-RES-001] Creates a reservation on an accessible item.
      def create
        item = Item.kept.find(params[:item_id])
        reservation = Reservation.new(item: item, user: current_user)
        authorize reservation, :create?
        created = ReservationService.create!(
          item: item,
          user: current_user,
          estimated_date: reservation_params[:estimated_date],
          private_note: reservation_params[:private_note]
        )
        render json: { reservation: created.as_api_json }, status: :created
      rescue ReservationService::Error, ArgumentError, ActiveRecord::RecordInvalid => e
        skip_authorization unless @_pundit_policy_authorized
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      # [REQ-RES-001] [REQ-RES-006] Extends estimated_date / note (O5A).
      def update
        reservation = Reservation.find(params[:id])
        authorize reservation, :update?
        note = reservation_params.key?(:private_note) ? reservation_params[:private_note] : :unchanged
        updated = ReservationService.extend!(
          reservation: reservation,
          estimated_date: reservation_params.require(:estimated_date),
          private_note: note
        )
        render json: { reservation: updated.as_api_json }, status: :ok
      rescue ReservationService::Error, ArgumentError, ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      # [REQ-RES-001] Voluntary cancel (O6A).
      def destroy
        reservation = Reservation.find(params[:id])
        authorize reservation, :destroy?
        ReservationService.cancel!(reservation: reservation, actor: current_user)
        head :no_content
      rescue ReservationService::Error => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      private

      def reservation_params
        params.require(:reservation).permit(:estimated_date, :private_note)
      end
    end
  end
end
