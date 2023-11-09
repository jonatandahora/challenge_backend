defmodule ChallengeBackendWeb.Router do
  use ChallengeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ChallengeBackendWeb do
    pipe_through :api
    post("/accounts/login", AccountsController, :login)
    post("/accounts/", AccountsController, :sign_up)
    get("/accounts/balance/", AccountsController, :balance)
    get("/transactions/", TransactionsController, :list_transactions)
    post("/transactions/", TransactionsController, :do_transaction)
    patch("/transactions/:id/reverse", TransactionsController, :reverse_transaction)
  end
end
