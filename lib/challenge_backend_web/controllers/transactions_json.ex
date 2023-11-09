defmodule ChallengeBackendWeb.TransactionsJson do
  @moduledoc """
  View for TransactionsController
  """

  alias ChallengeBackendWeb.AccountsJson

  def transaction(%{transaction: transaction}) do
    %{
      data: %{
        id: transaction.id,
        payer: AccountsJson.user_account(%{user_account: transaction.payer}),
        receiver: AccountsJson.user_account(%{user_account: transaction.receiver}),
        amount: transaction.amount,
        idempotency_key: transaction.idempotency_key,
        processed_at: transaction.processed_at,
        reversed_at: transaction.reversed_at
      }
    }
  end

  def transaction_simplified(%{transaction: transaction}) do
    %{
      id: transaction.id,
      payer_id: transaction.payer_id,
      receiver_id: transaction.receiver_id,
      amount: transaction.amount,
      idempotency_key: transaction.idempotency_key,
      processed_at: transaction.processed_at,
      reversed_at: transaction.reversed_at
    }
  end

  def transaction_list(%{transactions: transactions}) do
    %{
      data:
        Enum.map(transactions, fn transaction ->
          transaction_simplified(%{transaction: transaction})
        end)
    }
  end
end
