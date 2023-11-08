defmodule ChallengeBackendWeb.AccountsJson do
  @doc """
  Renders the login token.
  """
  def login(%{token: token}) do
    %{data: %{token: token}}
  end

  def user_account(%{user_account: user_account}) do
    %{
      data: %{
        id: user_account.id,
        balance: user_account.balance,
        cpf: user_account.cpf,
        first_name: user_account.first_name,
        last_name: user_account.last_name
      }
    }
  end

  def balance(%{user_account: user_account}) do
    %{
      data: %{
        balance: user_account.balance
      }
    }
  end
end
