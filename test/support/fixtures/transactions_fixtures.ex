defmodule ChallengeBackend.TransactionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChallengeBackend.Transactions` context.
  """
  alias ChallengeBackend.AccountsFixtures

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    payer = AccountsFixtures.user_account_fixture()
    receiver = AccountsFixtures.user_account_fixture()

    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        amount: "1205",
        idempotency_key: Ecto.UUID.generate(),
        processed_at: ~U[2023-11-06 01:29:00.000000Z],
        payer_id: payer.id,
        receiver_id: receiver.id
      })
      |> ChallengeBackend.Transactions.create_transaction()

    transaction
  end
end
