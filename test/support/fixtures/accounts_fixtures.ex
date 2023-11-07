defmodule ChallengeBackend.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChallengeBackend.Accounts` context.
  """

  @doc """
  Generate a user_account.
  """
  def user_account_fixture(attrs \\ %{}) do
    {:ok, user_account} =
      attrs
      |> Enum.into(%{
        cpf: "29047912802",
        first_name: "some first_name",
        balance: "1250",
        last_name: "some last_name",
        password: "some password"
      })
      |> ChallengeBackend.Accounts.create_user_account()

    user_account
  end
end
