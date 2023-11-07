defmodule ChallengeBackend.Accounts.UserAccount do
  use Ecto.Schema
  import Ecto.Changeset
  import Brcpfcnpj.Changeset

  alias ChallengeBackend.Transactions.Transaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_accounts" do
    field :first_name, :string
    field :last_name, :string
    field :cpf, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :balance, :decimal

    has_many :paid_transactions, Transaction, foreign_key: :payer_id
    has_many :received_transactions, Transaction, foreign_key: :receiver_id

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(first_name last_name cpf password balance)a

  @doc false
  def changeset(user_account, attrs) do
    user_account
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:cpf)
    |> validate_length(:cpf, is: 11, message: "cpf format is invalid")
    |> validate_cpf(:cpf)
    |> validate_number(:balance, greater_than: 0)
    |> put_password_hash()
  end

  def update_balance_changeset(user_account, new_balance) do
    cast(user_account, %{balance: new_balance}, [:balance])
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} =
           changeset
       ),
       do: change(changeset, %{password_hash: Argon2.hash_pwd_salt(password), password: nil})

  defp put_password_hash(changeset), do: changeset
end
