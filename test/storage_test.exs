defmodule KVTest do
  use ExUnit.Case
  doctest KV

  @dets_path Application.get_env(:kv, :dets_path)

  setup do
    File.rm(@dets_path)
    {:ok, ref} = :dets.open_file(@dets_path, type: :set, auto_save: 1_000)
    :dets.delete_all_objects(ref)
  end

  describe "storage correct work with ttl" do
    test "should remove after ttl timeout" do
      KV.create("foo", "bar", 1)
      Process.sleep(2)
      assert [] == KV.read("foo")
    end

    test "should raise call create if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.create(:foo, "bar")
      end
    end

    test "should't update key after ttl timeout" do
      KV.create("foo", "bar", 1)

      Process.sleep(2)

      KV.update("foo", "baz")
      assert [] == KV.read("foo")
    end

    test "should raise call update if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.update(:foo, "bar")
      end
    end

    test "should not raise delete exist't key from storage" do
      KV.delete("foo")
      assert [] == KV.read("foo")
    end

    test "should raise call delete if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.delete(:foo)
      end
    end
  end
end
