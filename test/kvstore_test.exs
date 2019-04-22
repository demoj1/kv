defmodule KVTest do
  use ExUnit.Case
  doctest KV

  @dets_path Application.get_env(:kv, :dets_path)

  setup do
    File.rm(@dets_path)
    {:ok, ref} = :dets.open_file(@dets_path, type: :set, auto_save: 1000)
    :dets.delete_all_objects(ref)
  end
end
