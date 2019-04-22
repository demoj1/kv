defmodule KV.Router do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :kv
  end

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:urlencoded])
  plug(:match)
  plug(:dispatch)

  get "/:key" do
    send_resp(conn, 200, KV.read(key))
  end

  post "/:key" do
    {:ok, _, conn} = Plug.Conn.read_body(conn)

    ttl = KV.Utils.parse_ttl(conn.body_params)
    value = Map.get(conn.body_params, "value")

    KV.create(key, value, ttl)
    send_resp(conn, 200, "")
  end

  patch "/:key" do
    {:ok, _, conn} = Plug.Conn.read_body(conn)

    ttl = KV.Utils.parse_ttl(conn.body_params)
    value = Map.get(conn.body_params, "value")

    KV.update(key, value, ttl)
    send_resp(conn, 200, "")
  end

  delete "/:key" do
    KV.delete(key)
    send_resp(conn, 200, "")
  end

  match(_, do: send_resp(conn, 404, "Not found"))
end
