defmodule KV.Storage do
  @moduledoc false

  @dets_path Application.get_env(:kv, :dets_path, "./storage")

  use GenServer
  require Logger

  # ---------------- API ----------------

  @spec create(String.t(), any(), integer()) :: :ok
  def create(key, value, ttl \\ 10_000) when is_number(ttl) and is_binary(key) do
    GenServer.cast(__MODULE__, {:create, [{key, value, ttl}]})
  end

  @spec create(list[{String.t(), any(), integer()}]) :: :ok
  def create(key_values) do
    GenServer.cast(__MODULE__, {:create, key_values})
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

  # ---------------- Callbacks ----------------

  @spec start_link() :: no_return
  def start_link() do
    dets =
      case :dets.open_file(@dets_path, type: :set, auto_save: 1000) do
        {:ok, ref} ->
          ref

        {:error, reason} ->
          GenServer.stop(__MODULE__, reason)
      end

    GenServer.start_link(__MODULE__, dets, name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, nil}
  def init(dets) do
    {:ok, dets}
  end

  @impl true
  @spec terminate(any(), String.t()) :: :normal
  def terminate(reason, dets) do
    Logger.error("Stop storage server, with reason: #{inspect(reason)}")

    :dets.sync(dets)
    :dets.close(dets)
    :normal
  end

  # ---------------- Server ----------------

  @impl true
  def handle_cast({:create, key_values}, dets) do
    :dets.insert_new(dets, key_values)

    {:noreply, dets}
  end

  @impl true
  def handle_cast({:update, key, value, ttl}, dets) do
    case :dets.lookup(dets, key) do
      [{_, _, old_ttl}] ->
        :dets.insert(dets, {key, value, ttl || old_ttl})

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
  def handle_call({:read, key}, _from, dets) do
    res =
      case :dets.lookup(dets, key) do
        [{_, v, _}] -> v
        [] -> []
        otherwise -> otherwise
      end

    {:reply, res, dets}
  end
end
