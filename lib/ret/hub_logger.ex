defmodule Ret.HubLogger do
  use GenServer, restart: :temporary
  alias PhoenixClient.{Socket, Message}

  require Logger

  # TODO: 本当に60秒か要検証
  @timeout_interval 60_000

  def start_link({hub_sid}) do
    name = {:via, Registry, {Ret.Registry, "#{hub_sid}"}}
    GenServer.start_link(__MODULE__, {hub_sid}, [name: name, timeout: @timeout_interval])
  end

  def init({hub_sid}) do
    {:ok, file} = File.open("./logs/#{hub_sid}.log", [:write, :delayed_write, :append])
    IO.write(file, "Start logging for hub: #{hub_sid}\n")

    # make hub logger join to hub channel
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "hub_logger"}
    )

    new_timer = set_timer(@timeout_interval)

    {:ok, [hub_sid, file, new_timer]}
  end

  # handle timeout
  def handle_info(:timeout, [hub_sid, file, new_timer]) do
    Logger.info("miyoshi throygh handleinfo :timeout")
    {:stop, :timeout, [hub_sid, file, new_timer]}
  end

  # hundale all messages
  def handle_info(msg, [hub_sid, file, new_timer]) do
    IO.write(file, "#{inspect(msg)}\n")
    new_imer = set_timer(@timeout_interval)
    {:noreply, [hub_sid, file, new_timer]}
  end

  def terminate(reason, [hub_sid, file, new_timer]) do
    Logger.info("miyoshi throygh terminated :timeout")
    IO.write(file, "reason: #{reason} Terminated\n")
    File.close(file)
    Registry.unregister(Ret.Registry, hub_sid)
    {:shutdown, reason}
  end

  defp set_timer(timeout_interval) do
    new_timer = Process.send_after(self(), :timeout, timeout_interval)
  end
end
