defmodule ChallengeBackendWeb.Router do
  use ChallengeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ChallengeBackendWeb do
    pipe_through :api
  end
end
