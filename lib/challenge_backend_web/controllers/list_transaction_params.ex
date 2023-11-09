defmodule ChallengeBackendWeb.ListTransactionParams do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChallengeBackendWeb.ListTransactionParams

  embedded_schema do
    field(:from, :utc_datetime)
    field(:to, :utc_datetime)
  end

  @fields ~w(from to)a
  def changeset(attrs) do
    %ListTransactionParams{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_interval()
  end

  def validate_params(params) do
    case changeset(params) do
      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}

      %Ecto.Changeset{valid?: true, changes: changes} ->
        {:ok, changes}
    end
  end

  defp validate_interval(%{valid?: true, changes: %{from: from, to: to}} = changeset) do
    if DateTime.compare(from, to) == :gt do
      add_error(changeset, :from, "cannot be later than 'to'")
    else
      changeset
    end
  end

  defp validate_interval(changeset), do: changeset
end
