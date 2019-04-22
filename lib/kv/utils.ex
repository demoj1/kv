defmodule KV.Utils do
  @spec parse_ttl(map()) :: nil | integer()
  def parse_ttl(body) do
    ttl = Map.get(body, "ttl", nil)

    if is_nil(ttl) do
      nil
    else
      case Integer.parse(ttl) do
        {ttl, _} -> ttl
        :error -> nil
      end
    end
  end
end
