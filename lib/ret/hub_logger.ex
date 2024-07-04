defmodule Ret.HubLogger do
  use GenServer, restart: :temporary
  alias PhoenixClient.{Socket, Message}

  require Logger

  @log_dir "./logs"
  @timeout_interval 30000

  # interface to start
  def start_link({hub_sid}) do
    name = {:via, Registry, {Ret.Registry, "#{hub_sid}"}}
    GenServer.start_link(__MODULE__, {hub_sid}, name: name)
  end

  # interface to stop
  def stop_link({hub_sid}) do
    case Registry.lookup(Ret.Registry, hub_sid) do
      [{pid, _}] ->
        GenServer.stop(pid)
        :ok
      _ ->
        raise "Room dose not exist !"
    end
  end

  # callback to init
  def init({hub_sid}) do
    File.mkdir_p!(@log_dir)
    {:ok, file}
      = File.open("#{@log_dir}/#{hub_sid}.log", [:write, :delayed_write, :append])
    IO.write(file, "Start for #{hub_sid}\n")

    # make hub logger join to hub channel
    {:ok, _res, _channel} = PhoenixClient.Channel.join(
      Socket,
      "hub:#{hub_sid}",
      %{"profile" => "hub_logger"}
    )

    new_timer = Process.send_after(self(), :timeout, @timeout_interval)

    {:ok, [hub_sid, file, new_timer]}
  end

  # callback to handle timeout
  def handle_info(:timeout, [hub_sid, file, timer]) do
    Logger.info("miyomiyo")
    {:stop,  :timeout, [hub_sid, file, timer]}
  end

  # call back to hundale all messages
  def handle_info(msg, [hub_sid, file, timer]) do
    IO.write(file, "#{inspect(msg)}\n")
    new_timer = update_timer(timer)
    {:noreply, [hub_sid, file, new_timer]}
  end

   #callback to handle terminate
  def terminate(reason, [hub_sid, file, timer]) do
    IO.write(file, "Terminate by #{reason}\n")
    File.close(file)
    Registry.unregister(Ret.Registry, hub_sid)
    {:shutdown, reason}
  end


  # private functions
  defp update_timer(old_timer) do
    Process.cancel_timer(old_timer)
    new_timer = Process.send_after(self(), :timeout, @timeout_interval)
  end
end
