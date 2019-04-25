defmodule KV.Storage do
  @moduledoc false

  @type table() :: String.t()

  @dets_path Application.get_env(:kv, :dets_path, :storage)
  @auto_save Application.get_env(:kv, :auto_save, 1_000)
  @clear_timeout Application.get_env(:kv, :clear_timeout, 10_000)

  use GenServer
  require Logger

  # ---------------- API ----------------

  @spec create(String.t(), any(), integer()) :: :ok
  def create(key, value, ttl) when is_number(ttl) and is_binary(key) do
    GenServer.cast(__MODULE__, {:create, {key, value, ttl}})
  end

  @spec read(String.t()) :: any()
  def read(key) when is_binary(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  @spec update(String.t(), any(), integer() | nil) :: :ok
  def update(key, value, ttl \\ nil) when is_binary(key) do
    GenServer.cast(__MODULE__, {:update, key, value, ttl})
  end

  @spec delete(String.t()) :: :ok
  def delete(key) when is_binary(key) do
    GenServer.cast(__MODULE__, {:delete, key})
  end

  # Удалить записи, у которых вышел ttl.
  # Параметры
  # * `dets` - ссылка на таблицу.
  @spec remove_timeouts() :: :ok
  defp remove_timeouts() do
    GenServer.cast(__MODULE__, :clear)
    Process.sleep(@clear_timeout)
    remove_timeouts()
  end

  # ---------------- Server ----------------

  @impl true
  def handle_call({:read, key}, _from, dets) do
    res =
      case :dets.lookup(dets, key) do
        [{_, v, ttl}] ->
          now = System.system_time(:millisecond)

          if ttl <= now do
            Logger.debug("Removed #{key} ttl timeout: #{ttl} now: #{now}")
            KV.delete(key)
            []
          else
            v
          end

        otherwise ->
          otherwise
      end

    {:reply, res, dets}
  end

  @impl true
  def handle_cast({:create, {key, value, ttl}}, dets) do
    :dets.insert_new(dets, {key, value, System.system_time(:millisecond) + ttl})

    {:noreply, dets}
  end

  @impl true
  def handle_cast({:update, key, value, ttl}, dets) do
    case :dets.lookup(dets, key) do
      [{_, _, old_ttl}] ->
        ttl =
          unless is_nil(ttl) do
            System.system_time(:millisecond) + ttl
          else
            old_ttl
          end

        :dets.insert(dets, {key, value, ttl})

      [] ->
        nil
    end

    {:noreply, dets}
  end

  @impl true
  def handle_cast({:delete, key}, dets) do
    :dets.delete(dets, key)

    {:noreply, dets}
  end

  @impl true
  def handle_cast(:clear, dets) do
    current_time = System.system_time(:millisecond)

    ms = [{{:_, :_, :"$1"}, [{:<, :"$1", {:const, current_time}}], [true]}]
    count = :dets.select_delete(dets, ms)

    Logger.debug("Removed #{count} records")

    {:noreply, dets}
  end

  # ---------------- Callbacks ----------------

  @spec start_link() :: no_return
  def start_link() do
    dets =
      case :dets.open_file(
             @dets_path,
             type: :set,
             auto_save: @auto_save,
             repair: true
           ) do
        {:ok, ref} ->
          ref

        {:error, reason} ->
          Logger.error("Error on starup KV.Storage server, reason: #{reason}")
          GenServer.stop(__MODULE__, reason)
      end

    Task.start_link(fn -> remove_timeouts() end)
    GenServer.start_link(__MODULE__, dets, name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, nil}
  def init(dets) do
    {:ok, dets}
  end

  @impl true
  @spec terminate(any(), table()) :: :normal
  def terminate(reason, dets) do
    Logger.error("Stop kv storage server, with reason: #{inspect(reason)}")

    :dets.sync(dets)
    :dets.close(dets)
    :normal
  end
end
