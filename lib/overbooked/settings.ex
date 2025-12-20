defmodule Overbooked.Settings do
  @moduledoc """
  The Settings context for managing application configuration.
  """

  import Ecto.Query, warn: false
  alias Overbooked.Repo
  alias Overbooked.Settings.MailSetting

  @doc """
  Gets the mail setting singleton, creating a default one if it doesn't exist.
  """
  def get_mail_setting do
    case Repo.one(from m in MailSetting, limit: 1) do
      nil ->
        %MailSetting{}
        |> MailSetting.changeset(%{})
        |> Repo.insert!()

      mail_setting ->
        mail_setting
    end
  end

  @doc """
  Gets the mail setting for display (with decoded API key masked).
  """
  def get_mail_setting_for_display do
    mail_setting = get_mail_setting()
    # Mask the API key for display
    case mail_setting.mailgun_api_key do
      nil -> mail_setting
      key when byte_size(key) > 8 ->
        decoded = MailSetting.decode_api_key(key)
        masked = String.slice(decoded, 0, 4) <> "****" <> String.slice(decoded, -4, 4)
        %{mail_setting | mailgun_api_key: masked}
      _ -> mail_setting
    end
  end

  @doc """
  Updates the mail setting.
  """
  def update_mail_setting(attrs) do
    mail_setting = get_mail_setting()

    # Encode the API key if it's being updated and not masked
    attrs = encode_api_key_if_needed(attrs, mail_setting)

    mail_setting
    |> MailSetting.changeset(attrs)
    |> Repo.update()
  end

  defp encode_api_key_if_needed(attrs, existing_setting) do
    api_key = attrs["mailgun_api_key"] || attrs[:mailgun_api_key]

    cond do
      # No API key in attrs, keep existing
      is_nil(api_key) or api_key == "" ->
        Map.delete(attrs, "mailgun_api_key") |> Map.delete(:mailgun_api_key)

      # API key contains masked value (****), keep existing
      String.contains?(api_key, "****") ->
        Map.put(attrs, "mailgun_api_key", existing_setting.mailgun_api_key)

      # New API key, encode it
      true ->
        encoded = MailSetting.encode_api_key(api_key)
        Map.put(attrs, "mailgun_api_key", encoded)
    end
  end

  @doc """
  Returns a changeset for tracking mail setting changes.
  """
  def change_mail_setting(%MailSetting{} = mail_setting, attrs \\ %{}) do
    MailSetting.changeset(mail_setting, attrs)
  end

  @doc """
  Returns the decoded Mailgun configuration for use by the mailer.
  Returns nil if mail is not enabled.
  """
  def get_mailgun_config do
    mail_setting = get_mail_setting()

    if mail_setting.enabled do
      %{
        api_key: MailSetting.decode_api_key(mail_setting.mailgun_api_key),
        domain: mail_setting.mailgun_domain,
        from_email: mail_setting.from_email,
        from_name: mail_setting.from_name
      }
    else
      nil
    end
  end

  @doc """
  Sends a test email to verify the mail configuration works.
  """
  def send_test_email(to_email) do
    config = get_mailgun_config()

    if config do
      import Swoosh.Email

      email =
        new()
        |> to(to_email)
        |> Swoosh.Email.from({config.from_name, config.from_email})
        |> subject("Test Email from Hatchbridge Rooms")
        |> text_body("""
        This is a test email from Hatchbridge Rooms.

        If you received this, your Mailgun configuration is working correctly!

        Sent at: #{DateTime.utc_now() |> DateTime.to_string()}
        """)

      Overbooked.Mailer.deliver(email)
    else
      {:error, :mail_not_enabled}
    end
  end
end
