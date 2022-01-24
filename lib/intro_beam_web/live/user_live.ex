defmodule IntroBeamWeb.UserLive do
  use IntroBeamWeb, :live_view

  defmodule UserTask do
    defstruct task: "",
              worker_pid: nil,
              result: ""
  end

  def render(assigns) do
    ~H"""
    Σ 1..n = 1 + 2 + 3 + ... + n<br>
    <br>
    <.form let={f} for={:entry_form} phx-submit="calculate">
      <%= label f, :value, "Eingabe für n:" %>
      <%= text_input f, :value, autocomplete: "off" %>

      <%= submit "berechnen" %>
    </.form>

    <%= Map.values(@user_tasks)
        |> Enum.map(fn {task, result} -> %>
             <div>
               <div style="width: 150px; display:inline-block;">Σ 1..<%= task  %></div>
               <div style="display:inline-block;"> &nbsp; = &nbsp; <%= raw(result) %>
             </div>
    <% end) %>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, :user_tasks, %{})
    {:ok, socket}
  end

  def handle_event("calculate", %{"entry_form" => %{"value" => value}}, socket) do
    val = String.to_integer(value)
    from = self()
    {pid, _ref} = Process.spawn(fn -> calculate(from, val) end, [:monitor])

    user_tasks =
      Map.put(
        socket.assigns.user_tasks,
        pid,
        {value, "<span style=\"color: blue;\"> <b>Berechnung läuft noch...</b> </span>"}
      )

    {:noreply, assign(socket, :user_tasks, user_tasks)}
  end

  def handle_info({:user_task_update, worker_pid, result}, socket) do
    user_tasks = socket.assigns.user_tasks

    user_tasks =
      if values = Map.get(user_tasks, worker_pid) do
        {task, _} = values
        Map.put(user_tasks, worker_pid, {task, Integer.to_string(result)})
      else
        user_tasks
      end

    {:noreply, assign(socket, :user_tasks, user_tasks)}
  end

  def handle_info({:DOWN, _, _, _worker_pid, :normal} = _msg, socket) do
    {:noreply, socket}
  end

  def handle_info({:DOWN, _, _, worker_pid, _} = _msg, socket) do
    user_tasks = socket.assigns.user_tasks

    user_tasks =
      if values = Map.get(user_tasks, worker_pid) do
        {task, _} = values

        Map.put(
          user_tasks,
          worker_pid,
          {task, "<span style=\"color: red;\">FEHLER (Runtime Exception)</span>"}
        )
      else
        user_tasks
      end

    {:noreply, assign(socket, :user_tasks, user_tasks)}
  end

  # c "lib/intro_beam_web/live/user_live.ex"

  defp calculate(from, n) do
    if n == 13, do: div(13, 0)
    res = Enum.reduce(1..n, 0, fn n, acc -> acc + n end)
    # res = div((1 + n), 2)
    Process.send(from, {:user_task_update, self(), res}, [])
  end
end
