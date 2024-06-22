defmodule Ret.HubLogger do
  @idle_timeout 5000
  use GenServer, restart: :temporary
  alias PhoenixClient.{Socket, Message}

  require Logger

  def start_link({hub_sid}) do
    name = {:via, Registry, {Ret.Registry, "#{hub_sid}"}}
    GenServer.start_link(__MODULE__, {hub_sid}, name: name)
  end

  def init({hub_sid}) do
    {:ok, file} = File.open("./logs/#{hub_sid}.log", [:write, :delayed_write])
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "hub_logger"}
    )
    {:ok, hub_sid, file}
  end

  def handle_info(:timeout, {hub_sid, file}) do
    Logger.info("miyoshi: self:#{inspect(self())} file:#{inspect(file)}")
    IO.write(file, "Timeout\n")
    File.close(file)
    Registry.unregister(Ret.Registry, hub_sid)
    {:stop, :normal, :ok}
  end

  def handle_info(
    %PhoenixClient.Message{
      topic: hub_sid,
      event: "nafr",
    } = msg, {hub_sid, file}) do
    IO.write(file, "#{inspect(msg)}\n")
    {:noreply, {hub_sid, file}}
  end
end
