defmodule KV do
  use Application
  use Supervisor

  @port Application.get_env(:kv, :port, 8080)
  @ttl Application.get_env(:kv, :ttl, 10_000)

  @doc """
  Добавить новое значение в хранилище (операция выполняется асинхронно).
  > Если ключ присутсвовал в хранилище, вставка/обновление не произойдет.

  ### Параметры
  * `key`   - ключ.
  * `value` - значение.
  * `ttl`   - время жизни значения (в мс), после истечения которого,
  значение будет удалено из хранилища. По умолчанию `10_000` мс.

  ### Пример
      iex> KV.create("foo", "bar")
      :ok
  """
  @spec create(String.t(), any(), integer()) :: :ok
  defdelegate create(key, value, ttl \\ @ttl), to: KV.Storage

  @doc """
  Получить значение из хранилища.

  ### Параметры
  * `key` - ключ.

  ### Возвращает
  Значение в случае успеха, и пустой лист в случае отсутствия ключа.

  ### Пример
      iex> KV.read("foo")
      "bar"
  """
  @spec read(String.t()) :: any()
  defdelegate read(key), to: KV.Storage

  @doc """
  Обновить значение в хранилище.
  > Если ключ отсутствовал в хранилище, обновления не произойдет.
  > Если значение ttl не будет передано, ttl останется прежним.

  ### Параметры
  * `key`   - ключ.
  * `value` - новое значение.
  * `ttl`   - новое значение ttl (времени жизни), по умолчанию nil.

  ### Пример
      iex> KV.create("foo", "bar")
      iex> KV.update("foo", "baz")
      iex> KV.read("foo")
      "baz"
  """
  @spec update(String.t(), any(), integer() | nil) :: :ok
  defdelegate update(key, value, ttl \\ nil), to: KV.Storage

  @doc """
  Удалить значения из хранилища (операция выполняется асинхронно).

  ### Параметры
  * `key` - ключ для удаления.

  ### Пример
      iex> KV.delete("foo")
      iex> KV.read("foo")
      []
  """
  @spec delete(String.t()) :: :ok
  defdelegate delete(key), to: KV.Storage

  # ---------------- Callbacks ----------------

  @impl true
  def init(_) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, KV.Router, [], port: @port),
      worker(KV.Storage, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(__MODULE__, [])
  end
end
