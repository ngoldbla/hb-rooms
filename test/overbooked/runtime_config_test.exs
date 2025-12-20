defmodule Overbooked.RuntimeConfigTest do
  use ExUnit.Case, async: false

  alias Overbooked.RuntimeConfig

  @env_keys [
    "DATABASE_URL",
    "PGUSER",
    "PGPASSWORD",
    "PGHOST",
    "PGPORT",
    "PGDATABASE"
  ]

  setup do
    previous =
      for key <- @env_keys, into: %{} do
        {key, System.get_env(key)}
      end

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    :ok
  end

  test "strips a nested database url prefix" do
    System.put_env("DATABASE_URL", "postgresql://u:p@postgresql://u:p@host:5432/db")

    assert RuntimeConfig.fetch_database_url!() == "postgresql://u:p@host:5432/db"
  end

  test "normalizes a duplicated database path" do
    System.put_env("DATABASE_URL", "postgresql://u:p@host:5432/railway:5432/railway")

    assert RuntimeConfig.fetch_database_url!() == "postgresql://u:p@host:5432/railway"
  end

  test "builds a database url from PG* vars when DATABASE_URL looks like an unexpanded template" do
    System.put_env("DATABASE_URL", "{{Postgres.DATABASE_URL}}")
    System.put_env("PGUSER", "u")
    System.put_env("PGPASSWORD", "p")
    System.put_env("PGHOST", "host")
    System.put_env("PGPORT", "5432")
    System.put_env("PGDATABASE", "db")

    assert RuntimeConfig.fetch_database_url!() == "postgresql://u:p@host:5432/db"
  end

  test "includes PHX_HOST in allowed origins list" do
    assert RuntimeConfig.fetch_allowed_origins("example.com") == ["https://example.com"]
  end
end

