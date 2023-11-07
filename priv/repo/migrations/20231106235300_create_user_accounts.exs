defmodule ChallengeBackend.Repo.Migrations.CreateUserAccounts do
  use Ecto.Migration

  def change do
    create table(:user_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_name, :string
      add :last_name, :string
      add :cpf, :string
      add :password_hash, :string
      add :balance, :decimal

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:user_accounts, [:cpf])
  end
end
