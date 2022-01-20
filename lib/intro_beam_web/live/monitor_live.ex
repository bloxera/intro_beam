defmodule IntroBeamWeb.MonitorLive do
  use IntroBeamWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>System-Monitor</h1>

    <.form let={f} for={:entry_form} phx-submit="start">
      <%= label f, :value, "Anzahl Worker:" %>
      <%= text_input f, :value, autocomplete: "off" %>

      <%= submit "Worker starten" %>
    </.form>


    Abgeschlossene Worker-Tasks pro Sekunde:
    <%= Enum.map(@activity, fn {time, value, _load} -> %>
      <%= if time > 0 do %>
        <div style="display: flex;">
          <span>
            <%= time |>  Integer.to_string() |> String.pad_leading(3, "0") %> sec.: &nbsp; &nbsp;
            <%= value |> Integer.to_string() |> String.pad_leading(5, "0") %> &nbsp; &nbsp;
          </span>
          <div style={ "background: grey; color: silver;  opacity:#{(80 + rem(time, 3) * 10) / 100}; height:24px; width:#{ round(70 / @max_value * value) }%;"}> </div>
        </div>
      <% else %>
        <br>
      <% end %>
    <% end) %>
    <br>
    Scheduler-Auslastung:
    <%= Enum.map(@activity, fn {time, _value, load} -> %>
      <%= if time > 0 do %>
        <div style="display: flex;">
          <span>
            <%= time |>  Integer.to_string() |> String.pad_leading(3, "0") %> sec.: &nbsp; &nbsp;
            <%= round(load * 100) |> Integer.to_string() |> String.pad_leading(3, "0") %>%  &nbsp; &nbsp;
          </span>

          <div style={ "background:#{ if load < 1.0, do: :green, else: :red}; color: silver;  opacity:#{(80 + rem(time, 3) * 10) / 100}; height:24px; width:#{ round(min(load*100, 100) * 0.7) }%;"}> </div>
        </div>
      <% else %>
          <br>
      <% end %>
    <% end) %>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)
    initial_activity = Enum.to_list(for _i <- 1..10, do: {0, 0, 0})

    socket =
      socket
      |> assign(:activity, initial_activity)
      |> assign(:ctr, 0)
      |> assign(:max_value, 1)
      |> assign(:prev_times, IntroBeam.Load.Scheduler.wall_times())

    {:ok, socket}
  end

  def handle_event("start", %{"entry_form" => %{"value" => value}}, socket) do
    val = String.to_integer(value)

    for _n <- 1..val do
      IntroBeam.WorkerProcs.WorkerSupervisor.start_child()
    end

    {:noreply, socket}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)

    {ctr, last_activity} = GenServer.call(:WorkerServer, :get_num_completed)

    scheduler_usage = min(IntroBeam.Load.Scheduler.usage(socket.assigns.prev_times), 9.0)

    activity =
      [{ctr, last_activity, scheduler_usage}] ++ List.delete_at(socket.assigns.activity, 9)

    max_value = max(socket.assigns.max_value, last_activity)

    {:noreply,
     socket
     |> assign(:activity, activity)
     |> assign(ctr: ctr)
     |> assign(max_value: max_value)
     |> assign(prev_times: IntroBeam.Load.Scheduler.wall_times())}
  end
end
