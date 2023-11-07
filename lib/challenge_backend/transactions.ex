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

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

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
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  @spec do_transaction(%{
          :amount => any(),
          :payer_id => any(),
          :receiver_id => any(),
          optional(any()) => any()
        }) :: any()
  @doc """
  Validates and processes a transaction
  """

  def do_transaction(%{payer_id: payer_id, receiver_id: receiver_id, amount: amount} = attrs) do
    Multi.new()
    |> Multi.run(:payer, fn _, _ -> Accounts.get_user_account(payer_id) end)
    |> Multi.run(:receiver, fn _, _ -> Accounts.get_user_account(receiver_id) end)
    |> Multi.run(:validate, fn _, %{payer: payer} -> validate_balance(payer, amount) end)
    |> Multi.run(:transaction, fn _, _ -> create_transaction(attrs) end)
    |> Multi.run(:update_payer_balance, fn _, %{payer: payer, transaction: transaction} ->
      Accounts.subtract_balance(payer, transaction.amount)
    end)
    |> Multi.run(:update_receiver_balance, fn _,
                                              %{receiver: receiver, transaction: transaction} ->
      Accounts.add_balance(receiver, transaction.amount)
    end)
    |> Repo.transaction()
  end

  defp validate_balance(payer, amount) do
    if Decimal.compare(payer.balance, amount) == :lt do
      {:error, :not_enough_balance}
    else
      {:ok, nil}
    end
  end
end
