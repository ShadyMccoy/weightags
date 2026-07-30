module Api
  module V1
    # Base for the headless API. Bearer-token auth, no cookies, JSON only. Sets
    # Current.org from the key and binds the request to that org's row-level
    # security scope — the same isolation the web app gets, enforced in Postgres.
    class BaseController < ActionController::API
      # Throttle buckets live in a store of their own rather than Rails.cache:
      # the app's cache is :null_store under test (so the web app's sign-in
      # throttles can't fire across a suite run) and solid_cache in production,
      # which would turn every API request into a database write. Process-local
      # means the ceiling is per web container — this is an abuse backstop, not a
      # metered quota, so that's the right trade.
      THROTTLE_STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)

      # Per key, not per IP: integrations routinely share egress IPs, so an IP
      # ceiling would punish one tenant for another's traffic.
      RATE_LIMIT = 600
      RATE_WINDOW = 1.minute

      # Rejected credentials can't be attributed to a key, so they're counted per
      # IP instead. A token is ~252 bits and unguessable; this exists to stop a
      # misconfigured or hostile client from billing us unbounded digest lookups.
      AUTH_FAILURE_LIMIT = 60
      AUTH_FAILURE_WINDOW = 1.minute

      # Ordered: identify the caller, then charge the request to that key, then
      # bind the tenancy scope. An unauthenticated request never consumes an
      # authenticated tenant's budget.
      before_action :authenticate_api_key!
      before_action :throttle_by_key
      before_action :scope_to_org

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :unprocessable

      def self.throttle_bucket(kind, subject)
        "api-v1:throttle:#{kind}:#{subject}"
      end

      # Fixed-window counter, one shape for both limits. Rails' own `rate_limit`
      # covers the authenticated case, but it can't express "count only the
      # failures" — and two mechanisms for one job is worse than one that does
      # both. A fixed window can admit up to 2× the limit across a boundary; for a
      # backstop that's fine, and it costs one increment instead of a sorted set.
      def self.throttled?(kind, subject, limit:, window:)
        count = THROTTLE_STORE.increment(throttle_bucket(kind, subject), 1, expires_in: window)
        count.present? && count > limit
      end

      private

      attr_reader :current_api_key

      def authenticate_api_key!
        @current_api_key = ApiKey.authenticate(bearer_token)
        return deny_unauthenticated unless @current_api_key

        @current_api_key.mark_used!
        Current.org = @current_api_key.org
        log_credential
      end

      # Support and abuse-tracing need to know *which* credential made a call. The
      # key id is non-secret; the token never reaches a log (it only ever travels
      # in the Authorization header, which Rails does not log). `log_tags` carries
      # the request id, so this line ties to the rest of the request.
      def log_credential
        logger.info { "[API] key=#{current_api_key.public_id} org=#{current_api_key.org_id}" }
      end

      def throttle_by_key
        return unless self.class.throttled?(:key, current_api_key.public_id,
          limit: RATE_LIMIT, window: RATE_WINDOW)
        render_rate_limited(RATE_WINDOW)
      end

      # Unknown and revoked tokens land here identically — the caller must not be
      # able to tell which, and both are a 401.
      def deny_unauthenticated
        if self.class.throttled?(:auth_failure, request.remote_ip,
          limit: AUTH_FAILURE_LIMIT, window: AUTH_FAILURE_WINDOW)
          return render_rate_limited(AUTH_FAILURE_WINDOW)
        end

        render_error(:unauthorized,
          "Provide a valid API key as 'Authorization: Bearer <token>'.")
      end

      def bearer_token
        request.authorization.to_s[/\ABearer\s+(.+)\z/i, 1]&.strip
      end

      def current_org
        Current.org
      end

      # The user who minted the key — the actor attributed in the audit log.
      def current_actor
        current_api_key.user
      end

      # Bind this request to the key's org for Postgres row-level security, the
      # same GUC the web Tenancy concern sets per request.
      def scope_to_org
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql(
            [ "SELECT set_config('app.accessible_org_ids', ?, false)", current_org.id.to_s ]
          )
        )
      rescue => e
        Rails.logger.warn("[API] could not set RLS scope: #{e.message}")
      end

      def render_error(status, message, details = nil)
        body = { error: message }
        body[:details] = details if details.present?
        render json: body, status: status
      end

      def not_found
        render_error(:not_found, "Not found.")
      end

      def render_rate_limited(retry_after)
        response.set_header("Retry-After", retry_after.to_i.to_s)
        render_error(:too_many_requests,
          "Too many requests. Retry in #{retry_after.to_i} seconds.")
      end

      def unprocessable(error)
        render_error(:unprocessable_entity, error.message)
      end
    end
  end
end
