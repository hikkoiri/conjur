# frozen_string_literal: true

require 'command_class'
require 'authentication/webservices'

module Authentication

  Err = Errors::Authentication

  # Possible Errors Raised:
  # TODO: add errors

  Status = CommandClass.new(
    dependencies: {
      role_class: ::Role,
      resource_class: ::Resource,
      webservices_class: ::Authentication::Webservices,
      implemented_authenticators: Authentication::InstalledAuthenticators.authenticators(ENV),
      enabled_authenticators: ENV['CONJUR_AUTHENTICATORS']
    },
    inputs: %i(authenticator_name account status_webservice authenticator_webservice user_id)
  ) do

    def call
      validate_authenticator_exists
      validate_authenticator_implements_status_check

      validate_account_exists

      validate_user_has_access_to_status_route

      validate_authenticator_webservice_exists
      validate_webservice_is_whitelisted

      validate_authenticator_requirements
    end

    private

    def validate_authenticator_exists
      raise Err::AuthenticatorNotFound, @authenticator_name unless authenticator
    end

    def validate_authenticator_implements_status_check
      raise Err::StatusNotImplemented, @authenticator_name unless authenticator.method_defined?(:status)
    end

    def validate_account_exists
      raise Err::Security::AccountNotDefined, @account unless account_admin_role
    end

    def validate_user_has_access_to_status_route
      validate_status_webservice_exists
      validate_user_is_defined
      validate_user_has_access
    end

    def validate_status_webservice_exists
      raise Err::Security::ServiceNotDefined, status_webservice_name unless status_webservice_resource
    end

    def validate_authenticator_webservice_exists
      raise Err::Security::ServiceNotDefined, authenticator_webservice_name unless authenticator_webservice_resource
    end

    def validate_user_is_defined
      raise Err::Security::UserNotDefinedInConjur, @user_id unless user_role
    end

    def validate_user_has_access
      # Ensure user has access to the service
      raise Err::Security::UserNotAuthorizedInConjur,
            @user_id unless user_role.allowed_to?('authenticate', status_webservice_resource)
    end

    def validate_webservice_is_whitelisted
      is_whitelisted = whitelisted_webservices.include?(@authenticator_webservice)
      raise Err::Security::NotWhitelisted, authenticator_webservice_name unless is_whitelisted
    end

    def validate_authenticator_requirements
      authenticator.status
    end

    def audit_success
      @audit_event.(input: @authenticator_input, success: true, message: nil)
    end

    def audit_failure(err)
      @audit_event.(input: @authenticator_input, success: false, message: err.message)
    end

    def authenticator
      # The `@implemented_authenticators` map includes all authenticator classes that are implemented in
      # Conjur (`Authentication::AuthnOidc::Authenticator`, `Authentication::AuthnLdap::Authenticator`, etc.).

      @authenticator = @implemented_authenticators[@authenticator_name]
    end

    def account_admin_role
      @account_admin_role ||= @role_class["#{@account}:user:admin"]
    end

    def status_webservice_resource
      @resource_class[status_webservice_resource_id]
    end

    def status_webservice_resource_id
      @status_webservice.resource_id
    end

    def status_webservice_name
      @status_webservice.name
    end

    def authenticator_webservice_resource
      @resource_class[authenticator_webservice_resource_id]
    end

    def authenticator_webservice_resource_id
      @authenticator_webservice.resource_id
    end

    def authenticator_webservice_name
      @authenticator_webservice.name
    end

    def user_role
      @user_role ||= @role_class[user_role_id]
    end

    def user_role_id
      @user_role_id ||= @role_class.roleid_from_username(@account, @user_id)
    end

    def whitelisted_webservices
      @webservices_class.from_string(
        @account,
        @enabled_authenticators || Authentication::Common.default_authenticator_name
      )
    end
  end
end
