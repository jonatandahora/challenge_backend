defmodule ChallengeBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChallengeBackendWeb.Telemetry,
      ChallengeBackend.Repo,
      {DNSCluster, query: Application.get_env(:challenge_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChallengeBackend.PubSub},
      # Start a worker by calling: ChallengeBackend.Worker.start_link(arg)
      # {ChallengeBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      ChallengeBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChallengeBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChallengeBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
