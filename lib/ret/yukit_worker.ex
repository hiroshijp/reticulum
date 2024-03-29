defmodule Ret.YukitWorker do
  use GenServer, restart: :temporary
  alias PhoenixClient.{Socket}

  def start_link({hub_sid}) do
    name = {:via, Registry, {Ret.YukitRegistry, "#{hub_sid}"}}
    GenServer.start_link(__MODULE__, {hub_sid}, name: name)
  end

  # GenServer callbacks
  def init({hub_sid}) do
    {:ok, file} = File.open("./logs/#{hub_sid}.log", [:write, :delayed_write])
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "yukit_worker"}
    )
    {:ok, file}
  end

  # def handle_call({:join, session_id}, _from, files) do
  #   {:ok, file} = File.open("./logs/#{session_id}.log", [:write, :delayed_write])
  #   Map.put(files, session_id, file)
  #   {:reply, :ok, files}
  # end

  # def handle_info(
  #   %PhoenixClient.Message{
  #     event: "nafr",
  #     payload: %{"from_session_id" => session_id}
  #   } = msg,
  #   files
  # ) do

  #   if Map.has_key?(files, session_id) do
  #     file = Map.get(files, session_id)
  #     IO.write(file, "#{inspect(msg)}\n")
  #     {:noreply, files}
  #   else
  #     {:ok, file} = File.open("./logs/#{session_id}.log", [:write, :delayed_write])
  #     files = Map.put(files, session_id, file)
  #     IO.write(file, "#{inspect(msg)}\n")
  #   end
  # end

  def handle_info(msg, file) do
    IO.write(file, "#{inspect(msg)}\n")
    {:noreply, file}
  end
end
