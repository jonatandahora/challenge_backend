defmodule ChallengeBackendWeb.LoginParams do
  use Ecto.Schema
  import Ecto.Changeset
  import Brcpfcnpj.Changeset

  alias ChallengeBackendWeb.LoginParams

  embedded_schema do
    field(:cpf, :string)
    field(:password, :string)
  end

  @fields ~w(cpf password)a
  def changeset(attrs) do
    %LoginParams{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_cpf(:cpf)
    |> validate_length(:cpf, is: 11)
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
