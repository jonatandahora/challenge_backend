defmodule ChallengeBackendWeb.DoTransactionParams do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChallengeBackendWeb.DoTransactionParams
  alias Ecto.UUID

  embedded_schema do
    field(:receiver_id, UUID)
    field(:amount, :integer)
    field(:idempotency_key, :string)
  end

  @fields ~w(receiver_id amount idempotency_key)a
  def changeset(attrs) do
    %DoTransactionParams{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_number(:amount, greater_than: 0)
  end

  def validate_params(params) do
    case changeset(params) do
      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}

      %Ecto.Changeset{valid?: true, changes: changes} ->
        {:ok, changes}
    end
  end
end
