defmodule KV.TestCase do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: false

      @dets_path Application.get_env(:kv, :dets_path)
      @clear_timeout Application.get_env(:kv, :clear_timeout)
      @autosave Application.get_env(:kv, :auto_save)
      @ttl Application.get_env(:kv, :ttl)

      setup do
        {:ok, ref} = :dets.open_file(@dets_path, type: :set, auto_save: @autosave)
        :dets.delete_all_objects(ref)

        pid = Process.whereis(KV.Storage)

        {:ok, dets: ref, stor_pid: pid}
      end

      # Ожидать истечения ttl + некоторая дельта
      defp wait_ttl_timeout() do
        delta = 5
        Process.sleep(@ttl + delta)
      end

      # Ожидать выполнения handle_cast запроса
      defp wait_cast_call(pid) do
        :sys.get_status(pid, :infinity)
      end
    end
  end
end

ExUnit.start()
