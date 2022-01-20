defmodule IntroBeam.WorkerProcs.Worker do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  ## Callbacks

  @impl true
  def init(_state) do
    Process.send_after(self(), :work, 1000)
    {:ok, 0}
  end

  # handle every second a work package
  @impl true
  def handle_info(:work, state) do
    Process.send_after(self(), :work, 1000)
    _sum = Enum.reduce(1..500, 0, fn i, acc -> i + acc end)
    Process.send(:WorkerServer, {:work_completed, state + 1}, [])
    {:noreply, 0}
  end
end
