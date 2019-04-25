use Mix.Config

config :kv,
  dets_path: :test_storage,
  auto_save: 10_000,
  ttl: 200,
  clear_timeout: 1_500,
  port: 8080
