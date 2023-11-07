defmodule ChallengeBackend.Accounts.UserAccount do
  use Ecto.Schema
  import Ecto.Changeset
  import Brcpfcnpj.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_accounts" do
    field :first_name, :string
    field :last_name, :string
    field :cpf, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :balance, :decimal

    timestamps(type: :utc_datetime)
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

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} =
           changeset
       ),
       do: change(changeset, %{password_hash: Argon2.hash_pwd_salt(password), password: nil})

  defp put_password_hash(changeset), do: changeset
end
