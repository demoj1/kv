defmodule KV.RouterTest do
  alias KV.Router

  use ExUnit.Case, async: false
  use Plug.Test

  @dets_path Application.get_env(:kv, :dets_path)

  setup do
    File.rm(@dets_path)
    {:ok, ref} = :dets.open_file(@dets_path, type: :set, auto_save: 1_000)
    :dets.delete_all_objects(ref)
  end

  describe "router correct work" do
    test "create new record" do
      resp =
        conn(:post, "/foo", "value=bar&ttl=5")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call

      # даем dets время на запись
      Process.sleep(1)

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""

      assert "bar" == KV.read("foo")

      # Ждем истечения ttl
      Process.sleep(5)

      assert [] == KV.read("foo")
    end

    test "read exist't key" do
      resp = conn(:get, "/foo", "") |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""
    end

    test "read value" do
      KV.create("foo", "bar")

      resp =
        conn(:get, "/foo")
        |> call

      # даем dets время на запись
      Process.sleep(2)

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == "bar"

      # Ждем истечения ttl
      Process.sleep(5)

      resp =
        conn(:get, "/foo")
        |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""
    end

    test "update value without change ttl" do
      KV.create("foo", "bar")

      resp =
        conn(:patch, "/foo", "value=baz")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call

      # ждем окончания ttl
      Process.sleep(5)

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""

      assert [] == KV.read("foo")
    end

    test "update value with change ttl" do
      KV.create("foo", "bar")

      resp =
        conn(:patch, "/foo", "value=baz&ttl=100")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call

      # ждем окончания (предыдущего) ttl
      Process.sleep(5)

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""

      assert "baz" == KV.read("foo")
    end

    test "delete exist't key" do
      resp = conn(:delete, "/foo", "") |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""
    end

    test "delete exist key" do
      KV.create("foo", "bar", 1000)

      resp = conn(:delete, "/foo", "") |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""
    end

    test "not found" do
      resp = conn(:get, "/", "") |> call

      assert resp.state == :sent
      assert resp.status == 404
      assert resp.resp_body == "Not found"
    end
  end

  defp call(conn) do
    Router.call(conn, Router.init([]))
  end
end
