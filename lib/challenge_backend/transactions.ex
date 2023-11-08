defmodule ChallengeBackend.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias ChallengeBackend.{Accounts, Repo}
  alias ChallengeBackend.Transactions.Transaction
  alias Ecto.Multi

  @doc """
  Returns the list of transaction.

  ## Examples

      iex> list_transaction()
      [%Transaction{}, ...]

  """
  def list_transaction do
    Repo.all(Transaction)
  end

  @doc """
  Returns the list of transactions by a range of dates.

  ## Examples

      iex> list_by_date(~U[2023-10-06 01:29:00Z], ~U[2023-11-06 01:29:00Z])
      [%Transaction{}, ...]

  """
  def list_by_date(from, to, preloads \\ []) do
    query =
      from(transaction in Transaction,
        where: transaction.processed_at >= ^from,
        where: transaction.processed_at <= ^to,
        order_by: [desc: transaction.processed_at],
        preload: ^preloads
      )

    Repo.all(query)
  end

  @doc """
  Gets a single transaction.

  ## Examples

      iex> get_transaction(23)
      {:ok, %Transaction{}}

      iex> get_transaction(456)
      {:error, :not_found}

  """
  def get_transaction(id, preloads \\ []) do
    query = from(t in Transaction, where: t.id == ^id, preload: ^preloads)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Validates and processes a transaction
  """
  def do_transaction(%{payer_id: payer_id, receiver_id: receiver_id, amount: amount} = attrs) do
    Multi.new()
    |> Multi.run(:payer, fn _, _ -> Accounts.fetch_lock_user_account(payer_id) end)
    |> Multi.run(:receiver, fn _, _ -> Accounts.fetch_lock_user_account(receiver_id) end)
    |> Multi.run(:validate, fn _, %{payer: payer} -> validate_balance(payer, amount) end)
    |> Multi.run(:transaction, fn _, _ -> create_transaction(attrs) end)
    |> Multi.run(:updated_payer, fn _, %{payer: payer, transaction: transaction} ->
      Accounts.subtract_balance(payer, transaction.amount)
    end)
    |> Multi.run(:updated_receiver, fn _, %{receiver: receiver, transaction: transaction} ->
      Accounts.add_balance(receiver, transaction.amount)
    end)
    |> Repo.transaction()
    |> normalize_transaction_result()
  end

  @doc """
  Reverses a transaction
  """
  def reverse_transaction(transaction_id) do
    Multi.new()
    |> Multi.run(:transaction, fn _, _ -> get_transaction(transaction_id) end)
    |> Multi.run(:reversable, fn _, %{transaction: transaction} ->
      check_if_reversable(transaction)
    end)
    |> Multi.run(:payer, fn _, %{transaction: transaction} ->
      Accounts.fetch_lock_user_account(transaction.payer_id)
    end)
    |> Multi.run(:receiver, fn _, %{transaction: transaction} ->
      Accounts.fetch_lock_user_account(transaction.receiver_id)
    end)
    |> Multi.run(:validate, fn _, %{transaction: transaction, receiver: receiver} ->
      validate_balance(receiver, transaction.amount)
    end)
    |> Multi.update(
      :reversed_transaction,
      fn %{transaction: transaction} ->
        Transaction.changeset(transaction, %{reversed_at: DateTime.utc_now()})
      end
    )
    |> Multi.run(:updated_payer, fn _, %{payer: payer, transaction: transaction} ->
      Accounts.add_balance(payer, transaction.amount)
    end)
    |> Multi.run(:updated_receiver, fn _, %{receiver: receiver, transaction: transaction} ->
      Accounts.subtract_balance(receiver, transaction.amount)
    end)
    |> Repo.transaction()
    |> normalize_transaction_result()
  end

  defp validate_balance(user_account, amount) do
    if Decimal.compare(user_account.balance, amount) == :lt do
      {:error, :not_enough_balance}
    else
      {:ok, nil}
    end
  end

  defp check_if_reversable(transaction) do
    if is_nil(transaction.reversed_at) do
      {:ok, nil}
    else
      {:error, :already_reversed}
    end
  end

  defp normalize_transaction_result(transaction) do
    case transaction do
      {:ok, %{reversed_transaction: transaction}} ->
        {:ok, transaction}

      {:ok, %{transaction: transaction}} ->
        {:ok, transaction}

      {:error, step, %Ecto.Changeset{} = changeset, _changes} ->
        {:error, {step, errors_on(changeset)}}

      {:error, step, message, _changes} ->
        {:error, {step, message}}
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
