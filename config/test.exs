use Mix.Config

config :kv,
  dets_path: :test_storage,
  auto_save: 1,
  ttl: 100,
  clear_timeout: 1_000
