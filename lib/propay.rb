require "propay/version"
require 'builder'
require 'ostruct'

module Propay
  class ResponseError < RuntimeError;
  end

  CARD_TYPES = %w(Visa MasterCard AMEX Discover DinersClub JCB)

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= OpenStruct.new
      yield(configuration)
      current_path = File.expand_path(File.dirname(__FILE__))
      Dir["#{current_path}/modules/*.rb"].each {|file| require file }
    end
    
    def create_merchant_profile(options = {})
      soap_action("CreateMerchantProfile", options)
    end

    def find_or_create_payer(options = {})
      payer_id = soap_action("GetPayers", options)["GetPayersResponse"]["GetPayersResult"]["Payers"]["PayerInfo"].first["payerAccountId"] rescue false
      payer_id = soap_action("CreatePayerWithData", options)["CreatePayerWithDataResponse"]["CreatePayerWithDataResult"]["ExternalAccountID"] unless payer_id
      return payer_id
    end

    def create_payer(options = {})
      payer_id = soap_action("CreatePayerWithData", options)["CreatePayerWithDataResponse"]["CreatePayerWithDataResult"]["ExternalAccountID"] unless payer_id
    end

    # :name :card_number :address :address2 :country :state :zip :description :expiration :payer_id :card_type
    def add_payment_method(options = {})
      soap_action("CreatePaymentMethod", options.merge(:payer_id => (options[:payer_id] || find_or_create_payer(options))))
    end

    #    :payment_method_id :user_id || :payer_id
    def delete_payment_method(options = {})
      soap_action("DeletePaymentMethod", options.merge(:payer_id => (options[:payer_id] || find_or_create_payer(options))))
    end

    #    :user_id || payer_id
    def list_payment_methods(options = {})
      response = soap_action("GetAllPayerPaymentMethods", options.merge(:payer_id => (options[:payer_id] || find_or_create_payer(options))))["GetAllPayerPaymentMethodsResponse"]["GetAllPayerPaymentMethodsResult"]["PaymentMethods"]["PaymentMethodInformation"] rescue nil
      return response.class == Hash ? [response] : response
    end

    #    :payment_method_id :amount :comment :comment2 :merchant_profile_id :payer_id || :user_id
    def process_payment(options = {})
      soap_action("ProcessPaymentMethodTransaction", options.merge(:payer_id => (options[:payer_id] || find_or_create_payer(options))))["ProcessPaymentMethodTransactionResponse"]["ProcessPaymentMethodTransactionResult"]
    end

    #    :payment_method_id :amount :comment :comment2 :merchant_profile_id :payer_id || :user_id
    def authorize_payment(options = {})
      soap_action("AuthorizePaymentMethodTransaction", options.merge(:payer_id => (options[:payer_id] || find_or_create_payer(options))))["AuthorizePaymentMethodTransactionResponse"]["AuthorizePaymentMethodTransactionResult"]
    end

    # :amount :comment :comment2 :merchant_profile_id :transaction_id :payer_id || :user_id
    def capture_payment(options = {})
      soap_action("CapturePayment", options.merge(:payer_id => (options[:payer_id] || find_or_create_payer(options))))["CapturePaymentResponse"]["CapturePaymentResult"]
    end

    # :transaction_id, :merchant_profile_id
    def void_payment(options = {})
      soap_action("VoidPaymentV2", options)["VoidPaymentV2Response"]["VoidPaymentV2Result"]
    end

    # :amount, :transaction_id, :merchant_profile_id
    def refund_payment(options = {})
      soap_action("RefundPaymentV2", options)["RefundPaymentV2Response"]["RefundPaymentV2Result"]
    end

    def get_temp_token(options = {})
      result = soap_action('GetTempToken', options)
      raise result["GetTempTokenResponse"]["GetTempTokenResult"]["RequestResult"]["ResultMessage"] if result["GetTempTokenResponse"]["GetTempTokenResult"]["RequestResult"]["ResultValue"] == "FAILURE"
      result
    end

    private

    def soap_action(action, options = {})
      @options = options
      @partial = ERB.new(File.new("#{File.dirname(__FILE__)}/soap_actions/_auth.erb").read, nil, true).result(binding)
      xml = ERB.new(File.new("#{File.dirname(__FILE__)}/soap_actions/#{action}.erb").read, nil, true).result(binding)
      response = post_soap(xml, action)
      puts xml, ">>\n", response.inspect if options[:show_xml]
      return response
    end

    def post_soap(xml, action)
      Rails.logger.info "SENT: #{xml}"
      host = (Rails.env == 'production' ? "protectpay.propay.com" : "protectpaytest.propay.com")
      resp = Typhoeus::Request.post("https://#{host}/api/sps.svc", :body => xml, :headers => {'Host' => host, 'Content-Type' => "text/xml; charset=utf-8", "SOAPAction" => "http://propay.com/SPS/contracts/SPSService/#{action}"})
      Rails.logger.info "RECEIVED: #{resp.body}"
      return Hash.from_xml(resp.body)["Envelope"]["Body"]
    end
  end
end
