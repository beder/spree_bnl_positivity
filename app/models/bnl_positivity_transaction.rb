class BnlPositivityTransaction < ActiveRecord::Base
  has_one :payment, class: Spree::Payment, as: :source

  delegate :actions, :can_capture?, to: Spree::Gateway::BnlPositivity


  def actions
    payment.payment_method.actions
  end

  def can_capture?(*args)
    payment.payment_method.can_capture?(*args)
  end


  def identifier
    payment.gateway_options[:order_id]
  end

  def email
    payment.gateway_options[:email]
  end

  def currency
    payment.gateway_options[:currency]
  end

  def order_number
    payment.order.number
  end

  def split?(amount)
    payment.order.total.to_f != amount
  end

end
