# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :challenge_backend,
  ecto_repos: [ChallengeBackend.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :challenge_backend, ChallengeBackendWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: ChallengeBackendWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ChallengeBackend.PubSub,
  live_view: [signing_salt: "hil1+ShY"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :challenge_backend, ChallengeBackendWeb.Auth.Guardian,
  issuer: "challenge_backend",
  secret_key: "xT5gdlDmJrUKPQLWvhgtcALPnx3mYeAj6q1UyJ/mshiRhkYuFrw58VvbxNxTx4w1"

config :challenge_backend, ChallengeBackendWeb.Auth.Pipeline,
  module: ChallengeBackendWeb.Auth.Guardian,
  error_handler: ChallengeBackendWeb.Auth.ErrorHandler

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
