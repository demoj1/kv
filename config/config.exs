use Mix.Config

config :kv,
  port: 8080,
  # Периодичность сохранение таблицы на диск в мс
  auto_save: 1_000,
  dets_path: :storage,
  ttl: 10_000,
  clear_timeout: 10_000

if(Mix.env() == :test) do
  import_config "test.exs"
end
