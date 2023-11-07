defmodule ChallengeBackend.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ChallengeBackend.Repo

  alias ChallengeBackend.Accounts.UserAccount

  @doc """
  Returns the list of user_accounts.

  ## Examples

      iex> list_user_accounts()
      [%UserAccount{}, ...]

  """
  def list_user_accounts do
    Repo.all(UserAccount)
  end

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

  @doc """
  Updates a user_account.

  ## Examples

      iex> update_user_account(user_account, %{field: new_value})
      {:ok, %UserAccount{}}

      iex> update_user_account(user_account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_account(%UserAccount{} = user_account, attrs) do
    user_account
    |> UserAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_account.

  ## Examples

      iex> delete_user_account(user_account)
      {:ok, %UserAccount{}}

      iex> delete_user_account(user_account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_account(%UserAccount{} = user_account) do
    Repo.delete(user_account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_account changes.

  ## Examples

      iex> change_user_account(user_account)
      %Ecto.Changeset{data: %UserAccount{}}

  """
  def change_user_account(%UserAccount{} = user_account, attrs \\ %{}) do
    UserAccount.changeset(user_account, attrs)
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