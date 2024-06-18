defmodule Ret.HubLogger do
  use GenServer, restart: :temporary
  alias PhoenixClient.Socket
  require Logger

  def start_link({hub_sid}) do
    name = {:via, Registry, {Ret.Registry, "#{hub_sid}"}}
    Logger.info("miyoshi hub_logger.ex line8")
    GenServer.start_link(__MODULE__, {hub_sid}, name: name)
  end

  # GenServer callbacks
  def init({hub_sid}) do
    {:ok, file} = File.open("./logs/#{hub_sid}.log", [:write, :delayed_write])
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "hub_logger"}
    )
    {:ok, file}
  end

  def handle_info(msg, file) do
    IO.write(file, "#{inspect(msg)}\n")
    {:noreply, file}
  end
end
