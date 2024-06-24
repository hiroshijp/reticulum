defmodule Ret.HubLogger do
  use GenServer, restart: :temporary
  alias PhoenixClient.{Socket, Message}

  require Logger

  @timeout_interval 10000

  def start_link({hub_sid}) do
    name = {:via, Registry, {Ret.Registry, "#{hub_sid}"}}
    GenServer.start_link(__MODULE__, {hub_sid}, [name: name, timeout: 30000])
  end

  def init({hub_sid}) do
    {:ok, file} = File.open("./logs/#{hub_sid}.log", [:write, :delayed_write])

    # make hub logger join to hub channel
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "hub_logger"}
    )

    mew_timer = set_timer(@timeout_interval)

    {:ok, [hub_sid, file, new_imer]}
  end

  # handle timeout
  def handle_info(:timeout, [hub_sid, file, new_imer]) do
    {:stop, :timeout, [hub_sid, file, new_imer]}
  end

  # hundale all messages
  def handle_info(msg, [hub_sid, file, new_imer]) do
    IO.write(file, "#{inspect(msg)}\n")
    new_imer = set_timer(@timeout_interval)
    {:noreply, [hub_sid, file, new_imer]}
  end

  def terminate(reason, [hub_sid, file, new_imer]) do
    IO.write(file, "reason: #{reason} Terminated\n")
    File.close(file)
    Registry.unregister(Ret.Registry, hub_sid)
    {:shutdown, reason}
  end

  defp set_timer(timeout_interval) do
    new_imer = Process.send_after(self(), :timeout, timeout_interval)
  end
end
