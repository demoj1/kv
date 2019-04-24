defmodule KV.RouterTest do
  use KV.TestCase
  use Plug.Test

  alias KV.Router

  describe "router correct work" do
    test "create new record" do
      resp =
        conn(:post, "/foo", "value=bar&ttl=#{@ttl}")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""

      assert "bar" == KV.read("foo")

      # Ждем истечения ttl
      wait_ttl_timeout()

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

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == "bar"

      # Ждем истечения ttl
      wait_ttl_timeout()

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

      # Ждем истечения ttl
      wait_ttl_timeout()

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""

      assert [] == KV.read("foo")
    end

    test "update value with change ttl" do
      KV.create("foo", "bar")

      resp =
        conn(:patch, "/foo", "value=baz&ttl=#{@ttl * 2}")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""

      # ждем истечения (предыдущего) ttl
      wait_ttl_timeout()

      # так как ttl удвоенный, значение должно сохраняться
      assert "baz" == KV.read("foo")
    end

    test "delete exist't key" do
      resp = conn(:delete, "/foo", "") |> call

      assert resp.state == :sent
      assert resp.status == 200
      assert resp.resp_body == ""
    end

    test "delete exist key" do
      KV.create("foo", "bar")

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
