defmodule IntroBeam.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      IntroBeamWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: IntroBeam.PubSub},
      # Start the Endpoint (http/https)
      IntroBeamWeb.Endpoint,
      # Start a worker by calling: IntroBeam.Worker.start_link(arg)
      # {IntroBeam.Worker, arg}
      IntroBeam.Load.Scheduler,
      IntroBeam.WorkerProcs.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IntroBeam.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IntroBeamWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
