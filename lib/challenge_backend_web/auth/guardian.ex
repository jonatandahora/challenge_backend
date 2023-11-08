defmodule ChallengeBackendWeb.Auth.Guardian do
  use Guardian, otp_app: :challenge_backend
  alias ChallengeBackend.Accounts
  alias ChallengeBackend.Accounts.UserAccount

  def subject_for_token(%UserAccount{id: id}, _claims), do: {:ok, id}

  def resource_from_claims(%{"sub" => id}), do: Accounts.get_user_account(id)
end
