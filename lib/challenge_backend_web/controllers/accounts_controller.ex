defmodule ChallengeBackendWeb.AccountsController do
  use ChallengeBackendWeb, :controller

  alias ChallengeBackend.Accounts
  alias ChallengeBackendWeb.Auth.{Guardian, Pipeline}
  alias ChallengeBackendWeb.FallbackController

  action_fallback(FallbackController)
  plug(Pipeline when action not in [:login, :sign_up])

  def sign_up(conn, params) do
    with {:ok, user_account} <- Accounts.create_user_account(params) do
      conn
      |> put_status(201)
      |> put_view(json: ChallengeBackendWeb.AccountsJson)
      |> render(:user_account, %{user_account: user_account})
    end
  end

  def login(conn, %{"cpf" => cpf, "password" => password}) do
    case Accounts.login_user_account(cpf, password) do
      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(json: ChallengeBackendWeb.ErrorJSON)
        |> render(:"401")

      {:ok, user_account} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user_account)

        conn
        |> put_status(200)
        |> put_view(json: ChallengeBackendWeb.AccountsJson)
        |> render(:login, %{token: token})
    end
  end

  def balance(conn, _params) do
    user_account = Guardian.Plug.current_resource(conn)

    conn
    |> put_status(200)
    |> put_view(json: ChallengeBackendWeb.AccountsJson)
    |> render(:balance, %{user_account: user_account})
  end
end
