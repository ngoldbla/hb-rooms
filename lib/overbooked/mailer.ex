defmodule Overbooked.Mailer do
  @moduledoc """
  Mailer module with dynamic configuration support.

  Reads Mailgun configuration from the database if enabled,
  otherwise falls back to environment variable configuration.
  """

  @doc """
  Delivers an email using the configured adapter.

  Attempts to use database-configured Mailgun settings first.
  Falls back to application config if DB settings are not enabled.
  """
  def deliver(email) do
    config = get_dynamic_config()

    case config do
      nil ->
        # Fall back to application config (env vars)
        Swoosh.Mailer.deliver(email, mailer_config())

      mailgun_config ->
        # Use database-configured Mailgun
        adapter_config = [
          adapter: Swoosh.Adapters.Mailgun,
          api_key: mailgun_config.api_key,
          domain: mailgun_config.domain
        ]
        Swoosh.Mailer.deliver(email, adapter_config)
    end
  end

  @doc """
  Delivers an email using the configured adapter, raising on error.
  """
  def deliver!(email) do
    case deliver(email) do
      {:ok, result} -> result
      {:error, reason} -> raise "Failed to deliver email: #{inspect(reason)}"
    end
  end

  defp get_dynamic_config do
    # Only try to load from DB if the repo is available
    if Process.whereis(Overbooked.Repo) do
      try do
        Overbooked.Settings.get_mailgun_config()
      rescue
        _ -> nil
      end
    else
      nil
    end
  end

  defp mailer_config do
    Application.get_env(:overbooked, __MODULE__, [])
  end
end
