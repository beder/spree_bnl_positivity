require 'openssl'
require 'Base64'
require 'savon'

module Spree

  class BnlPositivityNotificationsController < StoreController
    skip_before_filter :verify_authenticity_token

    def notify
      order = current_order || raise(ActiveRecord::RecordNotFound)

      payment = order.payments.processing.last
      bnl_transaction = payment.source

      begin

        res = BnlPositivityApi.new(payment.payment_method.api_params).verify(bnl_transaction.payment_id, bnl_transaction.identifier)

        if res.success?
          bnl_transaction.update_attributes!(transaction_id: res.transaction_id)
          payment.pend

          order.next
          if order.complete?
            flash.notice = Spree.t(:order_processed_successfully)
            flash[:commerce_tracking] = "nothing special"
            session[:order_id] = nil
            redirect_to completion_route(order)
          else
            redirect_to checkout_state_path(order.state)
          end

        else
          payment.failure
          if res.code == BnlPositivityApi::USER_CANCELED
            flash[:error] = I18n.t('flash.cancel', :scope => 'bnl_positivity', :message => res.message)
          else
            flash[:error] = I18n.t('flash.generic_error', :scope => 'bnl_positivity', :message => res.message)
          end

          redirect_to checkout_state_path(:payment)
        end

      rescue Exception => ex
        payment.failure
        flash[:error] = I18n.t('flash.generic_error', :scope => 'bnl_positivity', :message => ex.message)
        redirect_to checkout_state_path(:payment)
      end

    end


    private

    def completion_route(order)
      order_path(order, :token => order.guest_token)
    end

  end

end