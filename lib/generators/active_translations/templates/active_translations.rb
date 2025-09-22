ActiveTranslations.configure do |config|
  config.type = ENV.fetch("GOOGLE_TRANSLATION_TYPE", "service_account")
  config.project_id = ENV.fetch("GOOGLE_TRANSLATION_PROJECT_ID", :missing_google_translation_project_id)
  config.private_key_id = ENV.fetch("GOOGLE_TRANSLATION_PRIVATE_KEY_ID", :missing_google_translation_private_key_id)
  config.private_key = ENV.fetch("GOOGLE_TRANSLATION_PRIVATE_KEY", :missing_google_translation_private_key)
  config.client_email = ENV.fetch("GOOGLE_TRANSLATION_CLIENT_EMAIL", :missing_google_translation_client_email)
  config.client_id = ENV.fetch("GOOGLE_TRANSLATION_CLIENT_ID", :missing_google_translation_client_id)
  config.auth_uri = ENV.fetch("GOOGLE_TRANSLATION_AUTH_URI", "https://accounts.google.com/o/oauth2/auth")
  config.token_uri = ENV.fetch("GOOGLE_TRANSLATION_TOKEN_URI", "https://oauth2.googleapis.com/token")
  config.auth_provider_x509_cert_url = ENV.fetch("GOOGLE_TRANSLATION_AUTH_PROVIDER_CERT_URL", "https://www.googleapis.com/oauth2/v1/certs")
  config.client_x509_cert_url = ENV.fetch("GOOGLE_TRANSLATION_CLIENT_CERT_URL", :missing_google_translation_client_cert_url)
  config.universe_domain = ENV.fetch("GOOGLE_TRANSLATION_UNIVERSE_DOMAIN", "googleapis.com")
end
