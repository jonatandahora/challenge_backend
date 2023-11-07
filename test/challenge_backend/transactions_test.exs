defmodule ChallengeBackend.TransactionsTest do
  use ChallengeBackend.DataCase

  alias ChallengeBackend.Transactions

  describe "transaction" do
    alias ChallengeBackend.AccountsFixtures
    alias ChallengeBackend.Transactions.Transaction

    import ChallengeBackend.TransactionsFixtures

    @invalid_attrs %{amount: nil, idempotency_key: nil, processed_at: nil, reversed_at: nil}

    test "list_transaction/0 returns all transaction" do
      transaction = transaction_fixture()
      assert Transactions.list_transaction() == [transaction]
    end

    test "list_by_date/2 returns all transactions within the date range given" do
      transaction1 = transaction_fixture(%{processed_at: ~U[2023-10-06 01:29:00.000000Z]})
      transaction2 = transaction_fixture(%{processed_at: ~U[2023-11-01 01:29:00.000000Z]})
      _transaction3 = transaction_fixture(%{processed_at: ~U[2023-11-06 01:29:00.000000Z]})

      assert Transactions.list_by_date(~U[2023-10-06 00:00:00.000000Z], ~U[2023-11-05 23:59:59Z]) == [
               transaction2,
               transaction1
             ]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Transactions.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      payer = AccountsFixtures.user_account_fixture()
      receiver = AccountsFixtures.user_account_fixture()

      valid_attrs = %{
        amount: "1205",
        idempotency_key: "some idempotency_key",
        processed_at: ~U[2023-11-06 01:29:00.000000Z],
        reversed_at: ~U[2023-11-06 01:29:00.000000Z],
        payer_id: payer.id,
        receiver_id: receiver.id
      }

      assert {:ok, %Transaction{} = transaction} = Transactions.create_transaction(valid_attrs)
      assert transaction.amount == Decimal.new("1205")
      assert transaction.idempotency_key == "some idempotency_key"
      assert transaction.processed_at == ~U[2023-11-06 01:29:00.000000Z]
      assert transaction.reversed_at == ~U[2023-11-06 01:29:00.000000Z]
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()

      update_attrs = %{
        amount: "4567",
        idempotency_key: "some updated idempotency_key",
        processed_at: ~U[2023-11-07 01:29:00.000000Z],
        reversed_at: ~U[2023-11-07 01:29:00.000000Z]
      }

      assert {:ok, %Transaction{} = transaction} =
               Transactions.update_transaction(transaction, update_attrs)

      assert transaction.amount == Decimal.new("4567")
      assert transaction.idempotency_key == "some updated idempotency_key"
      assert transaction.processed_at == ~U[2023-11-07 01:29:00.000000Z]
      assert transaction.reversed_at == ~U[2023-11-07 01:29:00.000000Z]
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Transactions.update_transaction(transaction, @invalid_attrs)

      assert transaction == Transactions.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Transactions.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Transactions.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Transactions.change_transaction(transaction)
    end

    test "do_transaction/1 processes a transaction succesfully" do
      payer = AccountsFixtures.user_account_fixture()
      receiver = AccountsFixtures.user_account_fixture()
      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1000)
      }
      {:ok, result} = Transactions.do_transaction(attrs)
    end
  end
end
