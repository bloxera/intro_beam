defmodule IntroBeam.WorkerProcs.Server do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: :WorkerServer)
  end

  ## Callbacks

  @impl true
  def init(_state) do
    Process.send_after(self(), :reset, 1000)
    {:ok, {0, 0, 0}}
  end

  # start counting received responses every second from 0
  @impl true
  def handle_info(:reset, {ctr, _last, cur} = _state) do
    Process.send_after(self(), :reset, 1000)
    {:noreply, {ctr + 1, cur, 0}}
  end

  # a worker process notifies the completion of a work package
  @impl true
  def handle_info({:work_completed, num}, {ctr, last, cur} = _state) do
    {:noreply, {ctr, last, cur + num}}
  end

  # external request to server to get the number of completes requests during last second
  @impl true
  def handle_call(:get_num_completed, _from, {ctr, last, _cur} = state) do
    {:reply, {ctr, last}, state}
  end
end
