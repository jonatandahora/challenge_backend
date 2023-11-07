defmodule ChallengeBackend.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :decimal
      add :idempotency_key, :string
      add :processed_at, :utc_datetime_usec
      add :reversed_at, :utc_datetime_usec

      add :payer_id, references(:user_accounts, type: :binary_id)
      add :receiver_id, references(:user_accounts, type: :binary_id)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:transactions, [:idempotency_key])
  end
end
