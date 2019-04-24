defmodule KVTest do
  use KV.TestCase

  describe "storage positive scenario" do
    test "should create value", %{stor_pid: stor_pid} do
      KV.create("foo", "bar")
      wait_cast_call(stor_pid)

      assert "bar" == KV.read("foo")
    end

    test "should read value", %{stor_pid: stor_pid} do
      KV.create("foo", "bar")
      wait_cast_call(stor_pid)

      assert "bar" == KV.read("foo")
    end

    test "should correct read exist't key" do
      assert [] == KV.read("baz")
    end

    test "should update value", %{stor_pid: stor_pid} do
      KV.create("foo", "bar")
      KV.update("foo", "baz")
      wait_cast_call(stor_pid)

      assert "baz" == KV.read("foo")
    end

    test "should correct update exist't key", %{stor_pid: stor_pid} do
      KV.update("foo", "bar")
      wait_cast_call(stor_pid)

      assert [] == KV.read("foo")
    end

    test "should delete value", %{stor_pid: stor_pid} do
      KV.create("foo", "bar")
      KV.delete("foo")
      wait_cast_call(stor_pid)

      assert [] == KV.read("foo")
    end

    test "should correct delete exist't key", %{stor_pid: stor_pid} do
      KV.delete("foo")
      wait_cast_call(stor_pid)

      assert [] == KV.read("foo")
    end
  end

  describe "storage correct work with ttl" do
    test "should't update key after ttl timeout", %{stor_pid: stor_pid} do
      KV.create("foo", "bar", @ttl)
      wait_cast_call(stor_pid)

      wait_ttl_timeout()

      KV.update("foo", "baz")
      assert [] == KV.read("foo")
    end

    test "should correct work auto clear", %{dets: dets, stor_pid: stor_pid} do
      KV.create("foo", "bar")
      wait_cast_call(stor_pid)

      # Ждем запуска очистки и просрочки ttl
      Process.sleep(@clear_timeout + @ttl)
      wait_cast_call(stor_pid)

      assert [] == :dets.lookup(dets, "foo")
    end

    test "should remove after ttl timeout", %{stor_pid: stor_pid} do
      KV.create("foo", "bar", @ttl)
      wait_cast_call(stor_pid)

      wait_ttl_timeout()

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
  end

  describe "storage correct check arguments" do
    test "should raise call create if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.create(:foo, "bar")
      end
    end

    test "should raise call update if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.update(:foo, "bar")
      end
    end

    test "should raise call delete if key not string" do
      assert_raise FunctionClauseError, ~r/.*no function clause matching.*/, fn ->
        KV.delete(:foo)
      end
    end
  end
end
