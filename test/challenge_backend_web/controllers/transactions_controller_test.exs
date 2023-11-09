defmodule ChallengeBackendWeb.TransactionsControllerTest do
  use ChallengeBackendWeb.ConnCase

  import ChallengeBackendWeb.Auth.Guardian

  alias ChallengeBackend.{Accounts, AccountsFixtures, Repo, TransactionsFixtures}

  @valid_attrs %{
    payer_id: Ecto.UUID.generate(),
    receiver_id: Ecto.UUID.generate(),
    amount: Enum.random(1..1000),
    idempotency_key: Ecto.UUID.generate()
  }
  @invalid_attrs %{
    payer_id: nil,
    receiver_id: nil,
    amount: nil,
    idempotency_key: nil
  }

  setup %{conn: conn} do
    payer = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})
    receiver = AccountsFixtures.user_account_fixture(%{balance: Decimal.new(1000)})

    {:ok, token, _} = encode_and_sign(payer, %{}, token_type: :access)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn, payer: payer, receiver: receiver}
  end

  describe "do transaction" do
    test "successful transaction ", %{conn: conn, receiver: receiver} do
      attrs = Map.merge(@valid_attrs, %{receiver_id: receiver.id})

      conn = post(conn, ~p"/api/transactions", attrs)

      assert json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      attrs = @invalid_attrs

      conn = post(conn, ~p"/api/transactions", attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders invalid amount error", %{conn: conn} do
      attrs = Map.merge(@valid_attrs, %{amount: -1234})

      conn = post(conn, ~p"/api/transactions", attrs)

      assert json_response(conn, 422) == %{"errors" => %{"amount" => ["must be greater than 0"]}}
    end

    test "renders invalid balance error", %{conn: conn, payer: payer, receiver: receiver} do
      Accounts.subtract_balance(payer, Decimal.new(1500))
      attrs = Map.merge(@valid_attrs, %{receiver_id: receiver.id})

      conn = post(conn, ~p"/api/transactions", attrs)

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => %{"validate" => "not_enough_balance"}}
             }
    end

    test "renders invalid imdepotency_key error", %{conn: conn, receiver: receiver} do
      transaction =
        TransactionsFixtures.transaction_fixture(%{idempotency_key: Ecto.UUID.generate()})

      attrs =
        Map.merge(@valid_attrs, %{
          idempotency_key: transaction.idempotency_key,
          receiver_id: receiver.id
        })

      conn = post(conn, ~p"/api/transactions", attrs)

      assert json_response(conn, 422) == %{
               "errors" => %{
                 "detail" => %{
                   "transaction" => %{"idempotency_key" => ["has already been taken"]}
                 }
               }
             }
    end
  end

  describe "reverse transaction" do
    test "successful reversal ", %{
      conn: conn,
      payer: payer,
      receiver: receiver
    } do
      attrs = Map.merge(@valid_attrs, %{amount: 1000, receiver_id: receiver.id})

      conn = post(conn, ~p"/api/transactions", attrs)
      transaction = json_response(conn, 201)["data"]

      payer = Repo.reload(payer)
      receiver = Repo.reload(receiver)

      assert Decimal.equal?(payer.balance, Decimal.new(0))
      assert Decimal.equal?(receiver.balance, Decimal.new(2000))

      conn = patch(conn, ~p"/api/transactions/#{transaction["id"]}/reverse", %{})

      assert reversed_transaction = json_response(conn, 200)["data"]

      payer = Repo.reload(payer)
      receiver = Repo.reload(receiver)

      assert Decimal.equal?(payer.balance, Decimal.new(1000))
      assert Decimal.equal?(receiver.balance, Decimal.new(1000))
      assert reversed_transaction["reversed_at"]
    end

    test "renders errors when original receiver balance is not enough", %{
      conn: conn,
      payer: payer,
      receiver: receiver
    } do
      attrs = Map.merge(@valid_attrs, %{amount: 1000, receiver_id: receiver.id})

      conn = post(conn, ~p"/api/transactions", attrs)
      transaction = json_response(conn, 201)["data"]

      payer = Repo.reload(payer)
      receiver = Repo.reload(receiver)

      assert Decimal.equal?(payer.balance, Decimal.new(0))
      assert Decimal.equal?(receiver.balance, Decimal.new(2000))

      Accounts.subtract_balance(receiver, Decimal.new(1500))

      conn = patch(conn, ~p"/api/transactions/#{transaction["id"]}/reverse", %{})

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => %{"validate" => "not_enough_balance"}}
             }
    end

    test "renders errors when transaction was already reversed", %{
      conn: conn,
      payer: payer,
      receiver: receiver
    } do
      attrs = Map.merge(@valid_attrs, %{amount: 1000, receiver_id: receiver.id})

      conn = post(conn, ~p"/api/transactions", attrs)
      transaction = json_response(conn, 201)["data"]

      payer = Repo.reload(payer)
      receiver = Repo.reload(receiver)

      assert Decimal.equal?(payer.balance, Decimal.new(0))
      assert Decimal.equal?(receiver.balance, Decimal.new(2000))

      conn = patch(conn, ~p"/api/transactions/#{transaction["id"]}/reverse", %{})

      assert reversed_transaction = json_response(conn, 200)["data"]

      conn = patch(conn, ~p"/api/transactions/#{reversed_transaction["id"]}/reverse", %{})

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => %{"reversable" => "already_reversed"}}
             }
    end
  end

  describe "list transactions by date" do
    test "with valid params ", %{conn: conn, payer: payer} do
      from = "2023-10-06 00:00:00.000000Z"
      to = "2023-11-06 00:00:00.000000Z"

      %{id: transaction1} =
        TransactionsFixtures.transaction_fixture(%{
          payer_id: payer.id,
          processed_at: ~U[2023-10-07 00:00:00.000000Z]
        })

      %{id: transaction2} =
        TransactionsFixtures.transaction_fixture(%{
          payer_id: payer.id,
          processed_at: ~U[2023-10-08 00:00:00.000000Z]
        })

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-11-08 00:00:00.000000Z]
      })

      conn = get(conn, ~p"/api/transactions?from=#{from}&to=#{to}")

      assert [%{"id" => ^transaction1}, %{"id" => ^transaction2}] =
               json_response(conn, 200)["data"]

      assert length(json_response(conn, 200)["data"]) == 2
    end

    test "with invalid params ", %{conn: conn, payer: payer} do
      from = "1"
      to = "2"

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-10-07 00:00:00.000000Z]
      })

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-10-08 00:00:00.000000Z]
      })

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-11-08 00:00:00.000000Z]
      })

      conn = get(conn, ~p"/api/transactions?from=#{from}&to=#{to}")

      assert json_response(conn, 422) == %{
               "errors" => %{"from" => ["is invalid"], "to" => ["is invalid"]}
             }
    end

    test "with invalid date range ", %{conn: conn, payer: payer} do
      from = "2023-11-06 00:00:00.000000Z"
      to = "2023-10-06 00:00:00.000000Z"

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-10-07 00:00:00.000000Z]
      })

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-10-08 00:00:00.000000Z]
      })

      TransactionsFixtures.transaction_fixture(%{
        payer_id: payer.id,
        processed_at: ~U[2023-11-08 00:00:00.000000Z]
      })

      conn = get(conn, ~p"/api/transactions?from=#{from}&to=#{to}")

      assert json_response(conn, 422) == %{"errors" => %{"from" => ["cannot be later than 'to'"]}}
    end
  end
end
