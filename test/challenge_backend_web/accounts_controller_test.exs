defmodule ChallengeBackendWeb.AccountsControllerTest do
  use ChallengeBackendWeb.ConnCase

  import ChallengeBackend.AccountsFixtures
  import ChallengeBackendWeb.Auth.Guardian

  @sign_up_attrs %{
    first_name: "John",
    last_name: "Doe",
    cpf: Brcpfcnpj.cpf_generate(),
    balance: 1000,
    password: "12345"
  }
  @invalid_sign_up_attrs %{
    first_name: nil,
    last_name: nil,
    cpf: nil,
    balance: nil,
    password: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "sign up" do
    test "renders user_account when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/sign_up", @sign_up_attrs)
      assert json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/sign_up", @invalid_sign_up_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "login" do
    test "login successfull with valid credentials", %{conn: conn} do
      user_account = %{id: user_account_id} = user_account_fixture(%{password: "123456"})

      conn = post(conn, ~p"/api/login", %{cpf: user_account.cpf, password: "123456"})
      assert token = json_response(conn, 200)["data"]["token"]

      assert {:ok, %{"sub" => ^user_account_id}} = decode_and_verify(token)
    end

    test "login failed with invalid password", %{conn: conn} do
      user_account = user_account_fixture(%{password: "123456"})

      conn = post(conn, ~p"/api/login", %{cpf: user_account.cpf, password: "654321"})

      assert %{"errors" => %{"detail" => "Unauthorized"}} == json_response(conn, 401)
    end

    test "login failed with invalid cpf", %{conn: conn} do
      user_account_fixture(%{password: "123456"})

      conn = post(conn, ~p"/api/login", %{cpf: Brcpfcnpj.cpf_generate(), password: "123456"})

      assert %{"errors" => %{"detail" => "Unauthorized"}} == json_response(conn, 401)
    end
  end

  describe "balance" do
    test "renders user_account balance when account is logged in", %{conn: conn} do
      user_account = user_account_fixture(%{balance: Decimal.new(1250)})
      {:ok, token, _} = encode_and_sign(user_account, %{}, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(~p"/api/balance")

      assert json_response(conn, 200)["data"]["balance"] == "1250"
    end

    test "renders error when account token is not added to header", %{conn: conn} do
      conn = get(conn, ~p"/api/balance")

      assert %{"error" => "unauthenticated"} == json_response(conn, 401)
    end
  end
end
