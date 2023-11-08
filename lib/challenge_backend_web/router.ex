defmodule ChallengeBackendWeb.Router do
  use ChallengeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ChallengeBackendWeb do
    pipe_through :api
    post("/login", AccountsController, :login)
    post("/sign_up", AccountsController, :sign_up)
    get("/balance/", AccountsController, :balance)
  end
end
