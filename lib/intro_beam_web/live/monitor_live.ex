defmodule IntroBeamWeb.MonitorLive do
  use IntroBeamWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Activity Monitor</h1>
    <p>Abgeschlossene Worker-Tasks pro Sekunde:</p>
    <%= Enum.map(@activity, fn {time, value} -> %>
      <%= if time > 0 do %>
        <div style="display: flex;">
          <span>
            <%= time |>  Integer.to_string() |> String.pad_leading(3, "0") %> sec.:
            <%= value |> Integer.to_string() |> String.pad_leading(5, "0") %> &nbsp; &nbsp;
          </span>
          <div style={ "background: grey; color: silver;  height:24px; width:#{ round(80 / @max_value * (value + (value - @max_value) * 5)) }%;"}> </div>
        </div>
      <% end %>
    <% end) %>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)
    initial_activity = Enum.to_list(for _i <- 1..10, do: {0, 0})
    socket =
      socket
      |> assign(:activity, initial_activity)
      |> assign(:ctr, 0)
      |> assign(:max_value, 1)
    {:ok, socket}
  end


  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)
    {ctr, last_activity} = resp = GenServer.call( :WorkerServer, :get_num_completed, 20000)
    activity = [resp] ++ List.delete_at(socket.assigns.activity, 9)

    max_value = max(socket.assigns.max_value, last_activity)

    {:noreply, socket |> assign(:activity, activity) |> assign(ctr: ctr) |> assign(max_value: max_value)}
  end

end
