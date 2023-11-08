defmodule ChallengeBackendWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :challenge_backend,
    module: ChallengeBackendWeb.Auth.Guardian

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end
