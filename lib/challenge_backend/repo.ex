defmodule ChallengeBackend.Repo do
  use Ecto.Repo,
    otp_app: :challenge_backend,
    adapter: Ecto.Adapters.Postgres
end
