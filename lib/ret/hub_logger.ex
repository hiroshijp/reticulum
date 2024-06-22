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
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "hub_logger"}
    )
    {:ok, {hub_sid, file}}
  end

  def handle_info(:timeout, {hub_sid, file}) do
    {:stop, :timeout, {hub_sid, file}}
  end

  def handle_info(msg, {hub_sid, file}) do
    IO.write(file, "#{inspect(hub_sid)}: #{inspect(msg)}\n")
    {:noreply, {hub_sid, file}}
  end

  def terminate(reason, {hub_sid, file}) do
    Logger.info("miyoshi")

    IO.write(file, "reason: #{reason} Terminated\n")
    File.close(file)
    Registry.unregister(Ret.Registry, hub_sid)
    {:shutdown, reason}
  end
end
