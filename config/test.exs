use Mix.Config

config :kv,
  dets_path: "./test/dets",
  ttl: 5,
  clear_timeout: 10
