defmodule ChallengeBackendWeb.AccountsJson do
  @moduledoc """
  View for AccountsController

  """

  @doc """
  Renders the login token.
  """
  def login(%{token: token}) do
    %{data: %{token: token}}
  end

  @doc """
  Renders an user_account
  """
  def user_account(%{user_account: user_account}) do
    %{
      data: %{
        id: user_account.id,
        balance: user_account.balance,
        cpf: user_account.cpf,
        first_name: user_account.first_name,
        last_name: user_account.last_name,
        created_at: user_account.inserted_at
      }
    }
  end

  @doc """
  Renders an user_account's balance.
  """
  def balance(%{user_account: user_account}) do
    %{
      data: %{
        balance: user_account.balance
      }
    }
  end
end
