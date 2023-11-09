defmodule ChallengeBackendWeb.TransactionsController do
  use ChallengeBackendWeb, :controller

  alias ChallengeBackend.Transactions
  alias ChallengeBackendWeb.Auth.Pipeline
  alias ChallengeBackendWeb.{DoTransactionParams, FallbackController, ListTransactionParams}

  action_fallback(FallbackController)
  plug(Pipeline)

  def do_transaction(conn, params) do
    with {:ok, params} <- DoTransactionParams.validate_params(params),
         {:ok, params} <- inject_payer_id(conn, params),
         {:ok, transaction} <- Transactions.do_transaction(params),
         {:ok, transaction} <- Transactions.get_transaction(transaction.id, [:payer, :receiver]) do
      conn
      |> put_status(201)
      |> put_view(json: ChallengeBackendWeb.TransactionsJson)
      |> render(:transaction, %{transaction: transaction})
    end
  end

  def reverse_transaction(conn, %{"id" => transaction_id}) do
    with {:ok, transaction} <- Transactions.reverse_transaction(transaction_id),
         {:ok, transaction} <- Transactions.get_transaction(transaction.id, [:payer, :receiver]) do
      conn
      |> put_status(200)
      |> put_view(json: ChallengeBackendWeb.TransactionsJson)
      |> render(:transaction, %{transaction: transaction})
    end
  end

  def list_transactions(conn, params) do
    user_account = Guardian.Plug.current_resource(conn)

    with {:ok, params} <- ListTransactionParams.validate_params(params),
         transactions when is_list(transactions) <-
           Transactions.list_by_payer_and_date(user_account.id, params.from, params.to) do
      conn
      |> put_status(200)
      |> put_view(json: ChallengeBackendWeb.TransactionsJson)
      |> render(:transaction_list, %{transactions: transactions})
    end
  end

  defp inject_payer_id(conn, params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        {:error, {:payer, :not_found}}

      payer_account ->
        {:ok, Map.put(params, :payer_id, payer_account.id)}
    end
  end
end
