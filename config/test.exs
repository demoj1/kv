use Mix.Config

config :kv,
  dets_path: :test_storage,
  ttl: 100,
  clear_timeout: 1_000
