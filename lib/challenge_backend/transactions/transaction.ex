defmodule ChallengeBackend.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChallengeBackend.Accounts.UserAccount

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :amount, :decimal
    field :idempotency_key, :string
    field :processed_at, :utc_datetime_usec
    field :reversed_at, :utc_datetime_usec

    belongs_to :payer, UserAccount
    belongs_to :receiver, UserAccount

    timestamps(type: :utc_datetime_usec)
  end

  @fields ~w(amount idempotency_key processed_at reversed_at payer_id receiver_id)a
  @required @fields -- [:processed_at, :reversed_at]

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @fields)
    |> prepare_changes(fn changeset ->
      if is_nil(get_change(changeset, :processed_at)) do
        put_change(changeset, :processed_at, DateTime.utc_now())
      else
        changeset
      end
    end)
    |> validate_required(@required)
    |> validate_number(:amount, greater_than: 0)
    |> validate_ids()
    |> unique_constraint(:idempotency_key)
    |> foreign_key_constraint(:payer_id)
    |> foreign_key_constraint(:receiver_id)
  end

  defp validate_ids(%{changes: %{payer_id: payer_id, receiver_id: receiver_id}} = changeset)
       when payer_id == receiver_id do
    add_error(changeset, :payer_id, "payer can't be the same as receiver")
  end

  defp validate_ids(changeset), do: changeset
end
