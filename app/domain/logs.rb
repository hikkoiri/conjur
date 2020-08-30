# frozen_string_literal: true

module LogMessages

  module Conjur

    PrimarySchema = ::Util::TrackableLogMessageClass.new(
      msg:  "Primary schema is {0-primary-schema}",
      code: "CONJ00034I"
    )

    FipsModeStatus = ::Util::TrackableLogMessageClass.new(
      msg:  "OpenSSL FIPS mode set to {0}",
      code: "CONJ00038I"
    )

  end

  module Authentication

    OriginValidated = ::Util::TrackableLogMessageClass.new(
      msg:  "Origin validated",
      code: "CONJ00003D"
    )

    ValidatingAnnotationsWithPrefix = ::Util::TrackableLogMessageClass.new(
      msg:  "Validating annotations with prefix {0-prefix}",
      code: "CONJ00025D"
    )

    RetrievedAnnotationValue = ::Util::TrackableLogMessageClass.new(
      msg:  "Retrieved value of annotation {0-annotation-name}",
      code: "CONJ00024D"
    )

    ContainerNameAnnotationDefaultValue = ::Util::TrackableLogMessageClass.new(
      msg:  "Annotation '{0-authentication-container-annotation-name}' not found. " \
                "Using default value '{1-default-authentication-container}'",
      code: "CONJ00033D"
    )

    ValidatedResourceRestrictionValue = ::Util::TrackableLogMessageClass.new(
      msg:  "Resource restriction '{0-resource-restriction-name}' value validated",
      code: "CONJ00043D"
    )

    ValidatingResourceRestrictions = ::Util::TrackableLogMessageClass.new(
      msg:  "Validating resource restriction for role '{0-role-id}'",
      code: "CONJ00046D"
    )

    ValidatedResourceRestrictions = ::Util::TrackableLogMessageClass.new(
      msg:  "Resource restrictions validated",
      code: "CONJ00030D"
    )

    EncodedJWTResponse = ::Util::TrackableLogMessageClass.new(
      msg:  "Responding with a base64 encoded access token",
      code: "CONJ00039D"
    )

    module OAuth

      IdentityProviderUri = ::Util::TrackableLogMessageClass.new(
        msg:  "Working with Identity Provider {0-provider-uri}",
        code: "CONJ00007D"
      )

      IdentityProviderDiscoverySuccess = ::Util::TrackableLogMessageClass.new(
        msg:  "Identity Provider discovery succeeded",
        code: "CONJ00008D"
      )

      FetchProviderKeysSuccess = ::Util::TrackableLogMessageClass.new(
        msg:  "Fetched Identity Provider keys from provider successfully",
        code: "CONJ00009D"
      )

      IdentityProviderKeysFetchedFromCache = ::Util::TrackableLogMessageClass.new(
        msg:  "Fetched Identity Provider keys from cache successfully",
        code: "CONJ00017D"
      )

      ValidateProviderKeysAreUpdated = ::Util::TrackableLogMessageClass.new(
        msg:  "Validating that Identity Provider keys are up to date",
        code: "CONJ00019D"
      )

    end

    module Jwt

      TokenDecodeSuccess = ::Util::TrackableLogMessageClass.new(
        msg:  "Token decoded successfully",
        code: "CONJ00005D"
      )

      TokenDecodeFailed = ::Util::TrackableLogMessageClass.new(
        msg:  "Failed to decode the token with the error '{0-exception}'",
        code: "CONJ00018D"
      )

      ExtractedClaimFromToken = ::Util::TrackableLogMessageClass.new(
        msg:  "Extracted claim '{0-claim-name}' with value {1-claim-value} from token",
        code: "CONJ00031D"
      )

      ExtractedUsernameFromToken = ::Util::TrackableLogMessageClass.new(
        msg:  "Extracted username '{0}' from token",
        code: "CONJ00038D"
      )

    end

    module AuthnOidc

      ExtractedUsernameFromIDToken = ::Util::TrackableLogMessageClass.new(
        msg:  "Extracted username '{0}' from ID token claim '{1-id-token-username-claim}'",
        code: "CONJ00004D"
      )

    end

    module AuthnK8s

      PodChannelOpen = ::Util::TrackableLogMessageClass.new(
        msg:  "Pod '{0-pod-name}' : channel open",
        code: "CONJ00010D"
      )

      PodChannelClosed = ::Util::TrackableLogMessageClass.new(
        msg:  "Pod '{0-pod-name}' : channel closed",
        code: "CONJ00011D"
      )

      PodChannelData = ::Util::TrackableLogMessageClass.new(
        msg:  "Pod '{0-pod-name}', channel '{1-cahnnel-name}', data: {2-message-data}",
        code: "CONJ00012D"
      )

      PodMessageData = ::Util::TrackableLogMessageClass.new(
        msg:  "Pod: '{0-pod-name}', message: '{1-message-type}', data: '{2-message-data}'",
        code: "CONJ00013D"
      )

      PodError = ::Util::TrackableLogMessageClass.new(
        msg:  "Pod '{0-pod-name}' error : '{1}'",
        code: "CONJ00014D"
      )

      CopySSLToPod = ::Util::TrackableLogMessageClass.new(
        msg:  "Copying SSL certificate to {0-container-name}:{1-cert-file-path} " \
            "in {2-pod-namespace}/{3-pod-name}",
        code: "CONJ00015D"
      )

      CopySSLToPodSuccess = ::Util::TrackableLogMessageClass.new(
        msg:  "Copied SSL certificate successfully",
        code: "CONJ00037D"
      )

      ValidatingHostId = ::Util::TrackableLogMessageClass.new(
        msg:  "Validating host id {0}",
        code: "CONJ00026D"
      )

      HostIdFromCommonName = ::Util::TrackableLogMessageClass.new(
        msg:  "Host id {0} extracted from CSR common name",
        code: "CONJ00027D"
      )

      SetCommonName = ::Util::TrackableLogMessageClass.new(
        msg:  "Setting common name to {0-full-host-name}",
        code: "CONJ00028D"
      )

      PodExecCommand = ::Util::TrackableLogMessageClass.new(
        msg:  "Executing command '{0-command}' in container {1-container-name} of pod {2-pod-name}",
        code: "CONJ00047D"
      )

    end

    module AuthnIam

      GetCallerIdentityBody = ::Util::TrackableLogMessageClass.new(
        msg:  "AWS IAM get_caller_identity body:\n {0-response-body}",
        code: "CONJ00034D"
      )

      AttemptToMatchHost = ::Util::TrackableLogMessageClass.new(
        msg:  "IAM Role authentication attempt by AWS user {0-aws-user-id} " \
                  "with host to match = {1-host-to-match}",
        code: "CONJ00035D"
      )

      RetrieveIamIdentity = ::Util::TrackableLogMessageClass.new(
        msg:  "Retrieving IAM identity",
        code: "CONJ00036D"
      )

    end

    module AuthnAzure

      ExtractedResourceRestrictionsFromToken = ::Util::TrackableLogMessageClass.new(
        msg:  "Extracted resource restrictions from token",
        code: "CONJ00029D"
      )

    end

    module AuthnGce

      ExtractingRestrictionsFromResource = ::Util::TrackableLogMessageClass.new(
        msg: "Extracting resource restrictions with prefix '{0-prefix}' from role '{1-role-id}'",
        code: "CONJ00039D"
      )

      ExtractedResourceRestrictions = ::Util::TrackableLogMessageClass.new(
        msg: "{0-amount} resource restrictions were extracted",
        code: "CONJ00040D"
      )

      ValidatingResourceRestrictionsConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Validating resource restrictions configuration",
        code: "CONJ00041D"
      )

      ValidatedResourceRestrictionsConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restrictions configuration validated",
        code: "CONJ00042D"
      )

      ValidatingResourceRestrictionsValues = ::Util::TrackableLogMessageClass.new(
        msg: "Validating resource restriction values against Google ID token",
        code: "CONJ00044D"
      )

      ValidatedResourceRestrictionsValues = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restriction values validated",
        code: "CONJ00045D"
      )

    end
  end

  module Util

    RateLimitedCacheUpdated = ::Util::TrackableLogMessageClass.new(
      msg:  "Rate limited cache updated successfully",
      code: "CONJ00016D"
    )

    RateLimitedCacheLimitReached = ::Util::TrackableLogMessageClass.new(
      msg:  "Rate limited cache reached the '{0-limit}' limit and will not " \
              "call target for the next '{1-seconds}' seconds",
      code: "CONJ00020D"
    )

    ConcurrencyLimitedCacheUpdated = ::Util::TrackableLogMessageClass.new(
      msg:  "Concurrency limited cache updated successfully",
      code: "CONJ00021D"
    )

    ConcurrencyLimitedCacheReached = ::Util::TrackableLogMessageClass.new(
      msg:  "Concurrency limited cache reached the '{0-limit}' limit and will not call target",
      code: "CONJ00022D"
    )

    ConcurrencyLimitedCacheConcurrentRequestsUpdated = ::Util::TrackableLogMessageClass.new(
      msg:  "Concurrency limited cache concurrent requests updated to '{0-concurrent-requests}'",
      code: "CONJ00023D"
    )

  end
end
