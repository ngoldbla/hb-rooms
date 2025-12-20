defmodule Overbooked.RuntimeConfig do
  @moduledoc false

  @database_url_schemes ["postgresql://", "postgres://", "ecto://"]

  def fetch_database_url! do
    System.get_env("DATABASE_URL")
    |> normalize_database_url()
    |> case do
      nil ->
        build_database_url_from_pg_env() ||
          raise """
          environment variable DATABASE_URL is missing or invalid.

          Set DATABASE_URL to a full Postgres URL (recommended), e.g.:
          postgresql://USER:PASS@HOST:5432/DATABASE

          If you're on Railway, make sure you've added a reference from your PostgreSQL service to DATABASE_URL.
          """

      url ->
        url
    end
  end

  def fetch_phx_host do
    System.get_env("PHX_HOST") ||
      System.get_env("RAILWAY_PUBLIC_DOMAIN") ||
      System.get_env("RAILWAY_STATIC_URL") ||
      "example.com"
  end

  def fetch_allowed_origins(host) when is_binary(host) do
    extra =
      System.get_env("PHX_ALLOWED_ORIGINS", "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    Enum.uniq(["https://#{host}" | extra])
  end

  defp normalize_database_url(nil), do: nil

  defp normalize_database_url(url) do
    url = String.trim(url)

    cond do
      url == "" ->
        nil

      looks_like_unexpanded_template?(url) ->
        nil

      true ->
        url
        |> strip_leading_duplicate_scheme()
        |> normalize_postgres_path()
    end
  end

  defp looks_like_unexpanded_template?(url) do
    String.starts_with?(url, "{{") and String.ends_with?(url, "}}")
  end

  # Handles common misconfiguration where a full URL gets prepended to another full URL,
  # e.g. "postgresql://user:pass@postgresql://user:pass@host:5432/db"
  defp strip_leading_duplicate_scheme(url) do
    scheme_matches =
      Enum.flat_map(@database_url_schemes, fn scheme ->
        :binary.matches(url, scheme)
        |> Enum.map(fn {idx, _len} -> {idx, scheme} end)
      end)

    case scheme_matches do
      [] ->
        url

      [_one] ->
        url

      many ->
        {idx, _scheme} = Enum.max_by(many, fn {idx, _} -> idx end)
        String.slice(url, idx..-1//1)
    end
  end

  # Handles a second common misconfiguration where the database name gets duplicated with a port:
  # "/railway:5432/railway" -> "/railway"
  defp normalize_postgres_path(url) do
    uri = URI.parse(url)

    if uri.scheme in ["postgres", "postgresql"] and is_binary(uri.host) do
      fixed_path =
        case uri.path do
          nil ->
            nil

          path ->
            case String.split(path, ":", parts: 2) do
              [prefix, _rest] when is_binary(prefix) and prefix != "" -> prefix
              _ -> path
            end
        end

      %URI{uri | path: fixed_path}
      |> URI.to_string()
    else
      url
    end
  end

  defp build_database_url_from_pg_env do
    user = env_first(["PGUSER", "POSTGRES_USER", "POSTGRESQL_USER"])
    password = env_first(["PGPASSWORD", "POSTGRES_PASSWORD", "POSTGRESQL_PASSWORD"])
    host = env_first(["PGHOST", "POSTGRES_HOST", "POSTGRESQL_HOST"])
    database = env_first(["PGDATABASE", "POSTGRES_DB", "POSTGRESQL_DATABASE", "POSTGRES_DATABASE"])
    port = env_first(["PGPORT", "POSTGRES_PORT", "POSTGRESQL_PORT"])

    if present?(user) and present?(password) and present?(host) and present?(database) do
      port_part = if present?(port), do: ":#{port}", else: ""

      "postgresql://#{URI.encode_www_form(user)}:#{URI.encode_www_form(password)}@#{host}#{port_part}/#{database}"
    end
  end

  defp env_first(names) do
    Enum.find_value(names, &System.get_env/1)
  end

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(value) when is_binary(value), do: true
end

