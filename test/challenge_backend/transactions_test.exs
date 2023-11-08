defmodule ChallengeBackend.TransactionsTest do
  use ChallengeBackend.DataCase

  alias ChallengeBackend.Accounts
  alias ChallengeBackend.{AccountsFixtures, Transactions}
  alias ChallengeBackend.Transactions.Transaction

  describe "transaction" do
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

      assert Transactions.list_by_date(~U[2023-10-06 00:00:00.000000Z], ~U[2023-11-05 23:59:59Z]) ==
               [
                 transaction2,
                 transaction1
               ]
    end

    test "get_transaction/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Transactions.get_transaction(transaction.id) == {:ok, transaction}
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
  end

  describe "do_transaction/1" do
    test "do_transaction/1 processes a transaction succesfully" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1000)
      }

      {:ok, transaction} = Transactions.do_transaction(attrs)
      {:ok, transaction} = Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(transaction.payer.balance, Decimal.new(0))
      assert Decimal.equal?(transaction.receiver.balance, Decimal.new(2000))
    end

    test "do_transaction/1 can't process a transaction when payer has not enough balance" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1500)
      }

      assert {:error, {:validate, :not_enough_balance}} = Transactions.do_transaction(attrs)
    end

    test "do_transaction/1 can't process a transaction when payer and receiver are the same" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: payer.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1000)
      }

      assert {:error, {:transaction, %{payer_id: ["payer can't be the same as receiver"]}}} =
               Transactions.do_transaction(attrs)
    end

    test "do_transaction/1 can't process a transaction when receiver account doesn't exist" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: Ecto.UUID.generate(),
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1500)
      }

      assert {:error, {:receiver, :not_found}} = Transactions.do_transaction(attrs)
    end

    test "do_transaction/1 can't process a transaction when payer account doesn't exist" do
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: Ecto.UUID.generate(),
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1500)
      }

      assert {:error, {:payer, :not_found}} = Transactions.do_transaction(attrs)
    end

    test "do_transaction/1 can't process a transaction when amount is invalid" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(-1000)
      }

      assert {:error, {:transaction, %{amount: ["must be greater than 0"]}}} =
               Transactions.do_transaction(attrs)
    end

    test "do_transaction/1 can't process a duplicated transaction" do
      idempotency_key = Ecto.UUID.generate()
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(2000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: idempotency_key,
        amount: Decimal.new(1000)
      }

      {:ok, transaction} = Transactions.do_transaction(attrs)
      {:ok, transaction} = Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(transaction.payer.balance, Decimal.new(1000))
      assert Decimal.equal?(transaction.receiver.balance, Decimal.new(2000))

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: idempotency_key,
        amount: Decimal.new(1000)
      }

      assert {:error, {:transaction, %{idempotency_key: ["has already been taken"]}}} =
               Transactions.do_transaction(attrs)
    end
  end

  describe "reverse_transaction/1" do
    test "reverse_transaction/1 reverses an existing transaction succesfully" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1000)
      }

      {:ok, transaction} = Transactions.do_transaction(attrs)

      {:ok, transaction} = Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(transaction.payer.balance, Decimal.new(0))
      assert Decimal.equal?(transaction.receiver.balance, Decimal.new(2000))

      Transactions.reverse_transaction(transaction.id)

      {:ok, reversed_transaction} =
        Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(reversed_transaction.payer.balance, Decimal.new(1000))
      assert Decimal.equal?(reversed_transaction.receiver.balance, Decimal.new(1000))
    end

    test "reverse_transaction/1 can't reverse an existing transaction succesfully when receiver balance is not enough" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1000)
      }

      {:ok, transaction} = Transactions.do_transaction(attrs)

      {:ok, transaction} = Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(transaction.payer.balance, Decimal.new(0))
      assert Decimal.equal?(transaction.receiver.balance, Decimal.new(2000))

      Accounts.subtract_balance(transaction.receiver, Decimal.new(1500))

      assert {:error, {:validate, :not_enough_balance}} ==
               Transactions.reverse_transaction(transaction.id)
    end

    test "reverse_transaction/1 can't reverse an already reversed transaction" do
      payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
      receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

      attrs = %{
        payer_id: payer.id,
        receiver_id: receiver.id,
        idempotency_key: Ecto.UUID.generate(),
        amount: Decimal.new(1000)
      }

      {:ok, transaction} = Transactions.do_transaction(attrs)

      {:ok, transaction} = Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(transaction.payer.balance, Decimal.new(0))
      assert Decimal.equal?(transaction.receiver.balance, Decimal.new(2000))

      Transactions.reverse_transaction(transaction.id)

      {:ok, reversed_transaction} =
        Transactions.get_transaction(transaction.id, [:payer, :receiver])

      assert Decimal.equal?(reversed_transaction.payer.balance, Decimal.new(1000))
      assert Decimal.equal?(reversed_transaction.receiver.balance, Decimal.new(1000))

      assert {:error, {:reversable, :already_reversed}} ==
               Transactions.reverse_transaction(transaction.id)
    end
  end
end
