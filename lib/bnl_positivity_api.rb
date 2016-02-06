require 'openssl'
require 'base64'
require 'savon'

class BnlPositivityApi
  USER_CANCELED = 'IGFS_20090'

  def initialize(options)
    @server = options[:server]
    @key = options[:key]
    @tid = options[:terminal_id]
  end

  def authorize(amount, params)
    res = init_client.call(:init, message: { request: options_for_auth(amount, params) })

    AuthResponse.new(res.body[:init_response][:response])
  end

  def verify(payment_id, identifier)
    res = init_client.call(:verify, message: { request: options_for_verify(payment_id, identifier) })

    VerifyResponse.new(res.body[:verify_response][:response])
  end

  def capture(amount, params)
    res = pay_client.call(:confirm, message: { request: options_for_capture(amount, params) })

    Response.new(res.body[:confirm_response][:response])
  end


  private

  attr_reader :tid, :key, :server

  def options_for_auth(amount, params)

    options = {
      trType:         'AUTH',
      amount:         amount,

      tid:            tid,
      shopID:         params[:identifier],
      shopUserRef:    params[:email],
      currencyCode:   params[:currency],
      notifyURL:      params[:notify_url],
      errorURL:       params[:error_url],
      description:    params[:description],

      langID:         I18n.locale.to_s
    }

    options[:signature] = signature(
      options[:tid] +
      options[:shopID] +
      options[:shopUserRef] +
      options[:trType] +
      options[:amount].to_s +
      options[:currencyCode] +
      options[:langID] +
      options[:notifyURL] +
      options[:errorURL]
    )


    options
  end

  def options_for_verify(payment_id, identifier)

    options = {
      tid:        tid,
      paymentID:  payment_id,
      shopID:     identifier
    }

    options[:signature] = signature(
      options[:tid] +
      options[:shopID] +
      options[:paymentID]
    )

    options
  end

  def options_for_capture(amount, params)
    options = {
      amount:       amount,

      tid:          tid,
      shopID:       params[:identifier],
      refTranID:    params[:transaction_id],
      splitTran:    params[:split_tran]
    }

    options[:signature] = signature(
      options[:tid] +
      options[:shopID] +
      options[:amount].to_s +
      options[:refTranID]
    )

    options
  end

  def signature(data)
    Base64.encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)
    ).strip()
  end

  def init_client
    @init_client ||= ::Savon.client({
      wsdl: "#{server}/PaymentInitGatewayPort?wsdl",
      ssl_verify_mode: :none,
      pretty_print_xml: true,
      log: Rails.env.development?,
      convert_request_keys_to: :none
    })
  end

  def pay_client
    @pay_client ||= ::Savon.client({
      wsdl: "#{server}/PaymentTranGatewayPort?wsdl",
      ssl_verify_mode: :none,
      pretty_print_xml: true,
      log: Rails.env.development?,
      convert_request_keys_to: :none
    })
  end

  class Response

    def initialize(body)
      @body = body
    end

    def code
      body[:rc]
    end

    def success?
      !body.fetch(:error)
    end

    def message
      body.fetch(:error_desc)
    end
    alias_method :to_s, :message

    def authorization
      nil
    end

    private

    attr_reader :body

  end

  class AuthResponse < Response

    def payment_id
      body.fetch(:payment_id)
    end

    def redirect_url
      body.fetch(:redirect_url)
    end

  end

  class VerifyResponse < Response

    def transaction_id
      body.fetch(:tran_id)
    end

  end


end