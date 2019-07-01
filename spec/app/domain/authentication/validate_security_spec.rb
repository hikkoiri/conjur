# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateSecurity do
  let (:test_account) { 'test-account' }
  let (:non_existing_account) { 'non-existing' }
  let (:fake_authenticator_name) { 'authn-x' }
  
  # create an example webservice
  def webservice(service_id, account: test_account, authenticator_name: fake_authenticator_name)
    ::Authentication::Webservice.new(
      account: account,
      authenticator_name: authenticator_name,
      service_id: service_id
    )
  end

  # generates user_role authorized for all or no services
  def user_role(is_authorized:)
    double('user_role').tap do |role|
      allow(role).to receive(:allowed_to?).and_return(is_authorized)
    end
  end

  # generates user_role authorized for specific service
  def user_role_for_service(authorized_service)
    double('user_role').tap do |role|
      allow(role).to(receive(:allowed_to?)) do |_, resource|
        resource == authorized_service
      end
    end
  end

  def role_class(returned_role)
    double('role_class').tap do |role|
      allow(role).to receive(:roleid_from_username).and_return('some-role-id')
      allow(role).to receive(:[]).and_return(returned_role)
      
      allow(role).to receive(:[])
        .with(/#{test_account}:user:admin/)
        .and_return(user_role(is_authorized: true))
      
      allow(role).to receive(:[])
        .with(/#{non_existing_account}:user:admin/)
        .and_return(nil)
    end
  end

  # generates a Resource class which returns the provided object
  def resource_class(returned_resource)
    double('Resource').tap do |resource_class|
      allow(resource_class).to receive(:[]).and_return(returned_resource)
    end
  end

  let (:blank_env) { nil }

  let (:two_authenticator_env) { "#{fake_authenticator_name}/service1, #{fake_authenticator_name}/service2" }

  let(:default_authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn")
    end
  end

  let (:full_access_resource_class) { resource_class('some random resource') }
  let (:no_access_resource_class) { resource_class(nil) }

  let (:nil_user_role_class) { role_class(nil) }
  let (:non_existing_account_role_class) { role_class(nil) }
  let (:full_access_role_class) { role_class(user_role(is_authorized: true)) }
  let (:no_access_role_class) { role_class(user_role(is_authorized: false)) }

  context "A whitelisted, authorized webservice and authorized user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: full_access_role_class,
        resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: test_account,
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A un-whitelisted, authorized webservice and authorized user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: full_access_role_class,
        resource_class: full_access_resource_class
      ).(
        webservice: webservice('DOESNT_EXIST'),
          account: test_account,
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a NotWhitelisted error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::NotWhitelisted)
    end
  end

  context "A whitelisted, unauthorized webservice and authorized user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: full_access_role_class,
        resource_class: no_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: test_account,
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a ServiceNotDefined error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::ServiceNotDefined)
    end
  end

  context "A whitelisted, authorized webservice and non-existent user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: nil_user_role_class,
        resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: test_account,
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end
    it "raises a NotDefinedInConjur error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::UserNotDefinedInConjur)
    end
  end

  context "A whitelisted, authorized webservice and unauthorized user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: no_access_role_class,
        resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: test_account,
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a NotAuthorizedInConjur error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::UserNotAuthorizedInConjur
      )
    end
  end

  context "Two whitelisted, authorized webservices" do
    context "and a user authorized for only one on them" do
      let (:webservice_resource) { 'CAN ACCESS ME' }
      let (:partial_access_role_class) do
        role_class(user_role_for_service(webservice_resource))
      end
      let (:accessible_resource_class) { resource_class(webservice_resource) }
      let (:inaccessible_resource_class) { resource_class('CANNOT ACCESS ME') }

      context "when accessing the authorized one" do
        subject do
          Authentication::Security::ValidateSecurity.new(
            role_class: partial_access_role_class,
            resource_class: accessible_resource_class
          ).(
            webservice: webservice('service1'),
              account: test_account,
              user_id: 'some-user',
              enabled_authenticators: two_authenticator_env
          )
        end

        it "succeeds" do
          expect { subject }.to_not raise_error
        end
      end

      context "when accessing the blocked one" do
        subject do
          Authentication::Security::ValidateSecurity.new(
            role_class: partial_access_role_class,
            resource_class: inaccessible_resource_class
          ).(
            webservice: webservice('service1'),
              account: test_account,
              user_id: 'some-user',
              enabled_authenticators: two_authenticator_env
          )
        end

        it "fails" do
          expect { subject }.to raise_error(Errors::Authentication::Security::UserNotAuthorizedInConjur)
        end
      end
    end
  end

  context "An ENV lacking CONJUR_AUTHENTICATORS" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: full_access_role_class,
        resource_class: full_access_resource_class
      ).(
        webservice: default_authenticator_mock,
          account: test_account,
          user_id: 'some-user',
          enabled_authenticators: blank_env
      )
    end

    it "the default Conjur authenticator is included in whitelisted webservices" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        role_class: non_existing_account_role_class,
        resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: non_existing_account,
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises an AccountNotDefined error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::AccountNotDefined)
    end
  end

  context "when validating the same role a second time" do
    let(:user_id) { 'some-user' }
    let(:user_roleid) { [test_account, 'user', user_id].join(':') }
    let(:user_role_double) {
      double('user_role_double').tap { |ur|
        allow(ur).to receive(:allowed_to?).and_return(true)
      }
    }

    # We can't use the double returned by the +role_class+ function
    # above, because it doesn't constrain the arguments to +:[]+.
    let(:role_class) {
      double('role_class').tap {|rc|
        allow(rc).to receive(:roleid_from_username).and_return(user_roleid)
        allow(rc).to receive(:[])
          .with("#{test_account}:user:admin")
          .and_return(user_role(is_authorized: true))
      }
    }

    subject do
      described_class
        .new(
          role_class: role_class,
          resource_class: full_access_resource_class
        )
    end
    
    it "role lookups are not cached" do

      # Simulate two validations. For the first, the role should not
      # be found.
      allow(role_class).to receive(:[]).with(user_roleid).and_return(nil)
      expect { subject.(
                 webservice: webservice('service1'),
                 account: test_account,
                 user_id: user_id,
                 enabled_authenticators: two_authenticator_env
               )
      }.to raise_error(Errors::Authentication::Security::UserNotDefinedInConjur)

      # For the second, the role should be found, and validation
      # should succeed.

      # Note that, because the arguments are the same, this +allow+
      # overwrites the previous one.
      allow(role_class).to receive(:[]).with(user_roleid).and_return(user_role_double)
      expect { subject.(
                 webservice: webservice('service1'),
                 account: test_account,
                 user_id: user_id,
                 enabled_authenticators: two_authenticator_env
               )
      }.not_to raise_error
      
    end
  end
end
