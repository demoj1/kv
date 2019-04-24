defmodule KVTest do
  use KV.TestCase
  doctest KV

  describe "storage correct work with ttl" do
    test "correct work auto clear", %{dets: dets, stor_pid: stor_pid} do
      KV.create("foo", "bar")

      wait_cast_call(stor_pid)

      # Ждем запуска очистки и просрочки ttl
      Process.sleep(@clear_timeout + @ttl)

      assert [] == :dets.lookup(dets, "foo")
    end

    test "should remove after ttl timeout", %{stor_pid: stor_pid} do
      KV.create("foo", "bar", @ttl)

      wait_cast_call(stor_pid)
      wait_ttl_timeout()

      assert [] == KV.read("foo")
    end

    test "should raise call create if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.create(:foo, "bar")
      end
    end

    test "should't update key after ttl timeout", %{stor_pid: stor_pid} do
      KV.create("foo", "bar", @ttl)

      wait_cast_call(stor_pid)
      wait_ttl_timeout()

      KV.update("foo", "baz")
      assert [] == KV.read("foo")
    end

    test "should update key and ttl timeout", %{stor_pid: stor_pid} do
      KV.create("foo", "bar", @ttl)
      wait_cast_call(stor_pid)

      KV.update("foo", "baz", @ttl * 2)
      wait_cast_call(stor_pid)

      wait_ttl_timeout()

      assert "baz" == KV.read("foo")
    end

    test "should raise call update if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.update(:foo, "bar")
      end
    end

    test "should not raise delete exist't key from storage", %{stor_pid: stor_pid} do
      KV.delete("foo")
      wait_cast_call(stor_pid)

      assert [] == KV.read("foo")
    end

    test "should raise call delete if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.delete(:foo)
      end
    end
  end
end
