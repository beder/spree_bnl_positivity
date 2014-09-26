module Spree

  class BnlPositivityRedirectController < StoreController
    skip_before_filter :verify_authenticity_token

    def buy_now
      order = current_order || raise(ActiveRecord::RecordNotFound)

      transaction = BnlPositivityTransaction.create
      payment = order.payments.create!({
        amount:           order.total,
        payment_method:   payment_method,
        source:           transaction,
        response_code:    transaction.id
      })
      payment.started_processing


      res = BnlPositivityApi.new(payment_method.api_params).authorize(payment.amount.to_f, {
        identifier:     transaction.identifier,
        email:          transaction.email,
        currency:       transaction.currency.split('-').first,
        notify_url:     bnl_positivity_notify_url,
        error_url:      bnl_positivity_error_url,
        description:    I18n.t('bnl_positivity.transaction_description', host: request.host, order_number: transaction.order_number)
      })

      if res.success?
        transaction.update_attributes!(payment_id: res.payment_id)

        redirect_to res.redirect_url
      else
        payment.failure
        flash[:error] = I18n.t('flash.generic_error', :scope => 'bnl_positivity', :message => res.message)
        redirect_to checkout_state_path(:payment)
      end

    end


    private

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

  end


end