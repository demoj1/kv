defmodule KV do
  use Application

  @port Application.get_env(:kv, :port, 8080)

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, KV.Router, [], port: @port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
