# USAGE: GoogleTranslate.translate(target_language_code: "es-MX", text: "Hello world!")
# USAGE: GoogleTranslate.translate(target_language_code: "es-MX", text: Job.posted_status.last.title, obj: Job.posted_status.last)
# @see https://cloud.google.com/translate/docs/basic/translating-text

module ActiveTranslation
  class GoogleTranslate
    class << self
      def translate(target_language_code:, text:, source: "en-US", obj: nil)
        conn = Faraday.new(url: "https://translation.googleapis.com/") do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.request :authorization, "Bearer", -> { token }
        end

        response =
          conn.post(
            "language/translate/v2",
            {
              q: text,
              target: target_language_code,
              source: source,
            }
          )

        return nil unless response.success?

        parse_response(response)
      end

      private

      def parse_response(response)
        response.body.dig("data", "translations", 0, "translatedText")
        # CGI.unescapeHTML(translation) if translation.is_a?(String)
      end

      def token
        return "fake_access_token" if Rails.env.test?

        Rails.cache.fetch("google_access_token", expires_in: 55.minutes) do
          google_oauth_credentials = ActiveTranslation.configuration.to_json
          authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: StringIO.new(google_oauth_credentials),
            scope: [ "https://www.googleapis.com/auth/cloud-platform" ]
          )
          authorizer.fetch_access_token!
          authorizer.access_token
        end
      end
    end
  end
end
