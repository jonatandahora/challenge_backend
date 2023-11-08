defmodule ChallengeBackend.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ChallengeBackend.Repo

  alias ChallengeBackend.Accounts.UserAccount

  @doc """
  Gets a single user_account.


  ## Examples

      iex> get_user_account(123)
      {:ok, %UserAccount{}}

      iex> get_user_account!(456)
      {:error, :not_found}

  """
  def get_user_account(id) do
    case Repo.get(UserAccount, id) do
      nil -> {:error, :not_found}
      user_account -> {:ok, user_account}
    end
  end

  @doc """
  Fetchs a single user_account to be used in a transaction and locks it to prevent concurrency errors.


  ## Examples

      iex> fetch_lock_user_account(123)
      {:ok, %UserAccount{}}

      iex> fetch_lock_user_account!(456)
      {:error, :not_found}

  """
  def fetch_lock_user_account(id) do
    query = from(uc in UserAccount, where: uc.id == ^id, lock: "FOR UPDATE")

    case Repo.one(query) do
      nil -> {:error, :not_found}
      user_account -> {:ok, user_account}
    end
  end

  @doc """
  Creates a user_account.

  ## Examples

      iex> create_user_account(%{field: value})
      {:ok, %UserAccount{}}

      iex> create_user_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_account(attrs \\ %{}) do
    %UserAccount{}
    |> UserAccount.changeset(attrs)
    |> Repo.insert()
  end

  def add_balance(%UserAccount{} = user_account, %Decimal{} = amount) do
    new_amount = Decimal.add(user_account.balance, amount)

    user_account
    |> UserAccount.update_balance_changeset(new_amount)
    |> Repo.update()
  end

  def subtract_balance(%UserAccount{} = user_account, %Decimal{} = amount) do
    new_amount = Decimal.sub(user_account.balance, amount)

    user_account
    |> UserAccount.update_balance_changeset(new_amount)
    |> Repo.update()
  end
end
