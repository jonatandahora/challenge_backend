defmodule ChallengeBackend.AccountsTest do
  use ChallengeBackend.DataCase

  alias ChallengeBackend.Accounts

  describe "user_accounts" do
    alias ChallengeBackend.Accounts.UserAccount

    import ChallengeBackend.AccountsFixtures

    @invalid_attrs %{first_name: nil, last_name: nil, cpf: nil, password: nil, balance: nil}

    test "list_user_accounts/0 returns all user_accounts" do
      user_account = user_account_fixture()
      assert Accounts.list_user_accounts() == [user_account]
    end

    test "get_user_account/1 returns the user_account with given id" do
      user_account = user_account_fixture()
      assert Accounts.get_user_account(user_account.id) == {:ok, user_account}
    end

    test "create_user_account/1 with valid data creates a user_account" do
      valid_attrs = %{
        first_name: "some first_name",
        last_name: "some last_name",
        cpf: "53432419058",
        password: "some password",
        balance: "1200"
      }

      assert {:ok, %UserAccount{} = user_account} = Accounts.create_user_account(valid_attrs)
      assert user_account.first_name == "some first_name"
      assert user_account.last_name == "some last_name"
      assert user_account.cpf == "53432419058"
      assert Argon2.verify_pass("some password", user_account.password_hash)
      assert user_account.balance == Decimal.new("1200")
    end

    test "create_user_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user_account(@invalid_attrs)
    end

    test "create_user_account/1 with invalid balance returns error changeset" do
      invalid_attrs = Map.put(@invalid_attrs, :balance, Decimal.new(0))
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user_account(invalid_attrs)
      assert errors_on(changeset)[:balance]
    end

    test "create_user_account/1 with invalid cpf returns error changeset" do
      invalid_attrs = Map.put(@invalid_attrs, :cpf, "12345678900")
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user_account(invalid_attrs)
      assert errors_on(changeset)[:cpf]
    end

    test "create_user_account/1 with invalid cpf format returns error changeset" do
      invalid_attrs = Map.put(@invalid_attrs, :cpf, "123.456.789-00")
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user_account(invalid_attrs)
      assert errors_on(changeset)[:cpf]
    end

    test "create_user_account/1 with invalid cpf length returns error changeset" do
      invalid_attrs = Map.put(@invalid_attrs, :cpf, "123456")
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user_account(invalid_attrs)
      assert errors_on(changeset)[:cpf]
    end

    test "update_user_account/2 with valid data updates the user_account" do
      user_account = user_account_fixture()

      update_attrs = %{
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        cpf: "21946843601",
        password: "some updated password",
        balance: "4567"
      }

      assert {:ok, %UserAccount{} = user_account} =
               Accounts.update_user_account(user_account, update_attrs)

      assert user_account.first_name == "some updated first_name"
      assert user_account.last_name == "some updated last_name"
      assert user_account.cpf == "21946843601"
      assert Argon2.verify_pass("some updated password", user_account.password_hash)
      assert user_account.balance == Decimal.new("4567")
    end

    test "update_user_account/2 with invalid data returns error changeset" do
      user_account = user_account_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user_account(user_account, @invalid_attrs)

      assert {:ok, user_account} == Accounts.get_user_account(user_account.id)
    end

    test "delete_user_account/1 deletes the user_account" do
      user_account = user_account_fixture()
      assert {:ok, %UserAccount{}} = Accounts.delete_user_account(user_account)
      assert {:error, :not_found} = Accounts.get_user_account(user_account.id)
    end

    test "change_user_account/1 returns a user_account changeset" do
      user_account = user_account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user_account(user_account)
    end
  end
end
