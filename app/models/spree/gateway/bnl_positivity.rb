require 'bnl_positivity_api'

module Spree

  class Gateway::BnlPositivity < Gateway
    preference :server, :string, default: 'https://testbnl.netsw.it/BNL_CG_SERVICES/services'
    preference :key, :string
    preference :terminal_id, :string

    def api_params
      {
        server: preferred_server,
        key: preferred_key,
        terminal_id: preferred_terminal_id
      }
    end

    def source_required?
      false
    end

    def auto_capture?
      false
    end

    def actions
      %w{ capture }
    end

    def actions
      %w{ capture }
    end

    def can_capture?(payment)
      payment.source.present? && payment.source.transaction_id.present? && payment.pending? && payment.order.outstanding_balance >= payment.amount
    end

    def method_type
      'bnl_positivity'
    end

    def capture(amount, bnl_transaction_id, gateway_options={})
      bnl_transaction = BnlPositivityTransaction.find(bnl_transaction_id)

      BnlPositivityApi.new(bnl_transaction.payment.payment_method.api_params).capture(amount, {
        identifier:       bnl_transaction.identifier,
        transaction_id:   bnl_transaction.transaction_id,
        split_tran:       bnl_transaction.split?(amount)
      })
    end

  end

end