defmodule Overbooked.Settings do
  @moduledoc """
  The Settings context for managing application configuration.
  """

  import Ecto.Query, warn: false
  alias Overbooked.Repo
  alias Overbooked.Settings.MailSetting
  alias Overbooked.Settings.StripeSetting
  alias Overbooked.Settings.EmailTemplate
  alias Overbooked.Settings.DefaultTemplates
  alias Overbooked.Settings.ContractTerm

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

  # =============================================================================
  # Stripe Settings
  # =============================================================================

  @doc """
  Gets the stripe setting singleton, creating a default one if it doesn't exist.
  """
  def get_stripe_setting do
    case Repo.one(from s in StripeSetting, limit: 1) do
      nil ->
        %StripeSetting{}
        |> StripeSetting.changeset(%{})
        |> Repo.insert!()

      stripe_setting ->
        stripe_setting
    end
  end

  @doc """
  Gets the stripe setting for display (with secret keys masked).
  """
  def get_stripe_setting_for_display do
    stripe_setting = get_stripe_setting()

    stripe_setting
    |> mask_stripe_key(:secret_key)
    |> mask_stripe_key(:webhook_secret)
  end

  defp mask_stripe_key(setting, field) do
    case Map.get(setting, field) do
      nil -> setting
      "" -> setting
      key when byte_size(key) > 8 ->
        decoded = StripeSetting.decode_key(key)
        masked = String.slice(decoded, 0, 8) <> "****" <> String.slice(decoded, -4, 4)
        Map.put(setting, field, masked)
      _ -> setting
    end
  end

  @doc """
  Updates the stripe setting.
  """
  def update_stripe_setting(attrs) do
    stripe_setting = get_stripe_setting()

    # Encode secret keys if they're being updated and not masked
    attrs =
      attrs
      |> encode_stripe_key_if_needed(:secret_key, "secret_key", stripe_setting)
      |> encode_stripe_key_if_needed(:webhook_secret, "webhook_secret", stripe_setting)

    stripe_setting
    |> StripeSetting.changeset(attrs)
    |> Repo.update()
  end

  defp encode_stripe_key_if_needed(attrs, atom_key, string_key, existing_setting) do
    key_value = attrs[string_key] || attrs[atom_key]

    cond do
      # No key in attrs, keep existing
      is_nil(key_value) or key_value == "" ->
        attrs
        |> Map.delete(string_key)
        |> Map.delete(atom_key)

      # Key contains masked value (****), keep existing
      String.contains?(key_value, "****") ->
        Map.put(attrs, string_key, Map.get(existing_setting, atom_key))

      # New key, encode it
      true ->
        encoded = StripeSetting.encode_key(key_value)
        Map.put(attrs, string_key, encoded)
    end
  end

  @doc """
  Returns a changeset for tracking stripe setting changes.
  """
  def change_stripe_setting(%StripeSetting{} = stripe_setting, attrs \\ %{}) do
    StripeSetting.changeset(stripe_setting, attrs)
  end

  @doc """
  Returns the decoded Stripe configuration for use by the Stripe module.
  Falls back to environment variables if DB config is not enabled.
  """
  def get_stripe_config do
    stripe_setting = get_stripe_setting()

    if stripe_setting.enabled and stripe_setting.secret_key do
      %{
        secret_key: StripeSetting.decode_key(stripe_setting.secret_key),
        webhook_secret: StripeSetting.decode_key(stripe_setting.webhook_secret),
        publishable_key: stripe_setting.publishable_key,
        environment: stripe_setting.environment,
        source: :database
      }
    else
      # Fallback to environment variables
      %{
        secret_key: Application.get_env(:stripity_stripe, :api_key),
        webhook_secret: Application.get_env(:overbooked, :stripe_webhook_secret),
        publishable_key: nil,
        environment: "env",
        source: :environment
      }
    end
  end

  @doc """
  Tests the Stripe connection using the configured API key.
  """
  def test_stripe_connection do
    config = get_stripe_config()

    if config.secret_key do
      case Stripe.Balance.retrieve(api_key: config.secret_key) do
        {:ok, _balance} ->
          {:ok, :connected}

        {:error, %Stripe.Error{message: message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, "No Stripe API key configured"}
    end
  end

  # =============================================================================
  # Email Templates
  # =============================================================================

  @doc """
  Gets an email template by type.
  Returns the custom template from DB if exists, otherwise returns the default template.
  """
  def get_email_template(template_type) when is_atom(template_type) do
    get_email_template(Atom.to_string(template_type))
  end

  def get_email_template(template_type) when is_binary(template_type) do
    case Repo.get_by(EmailTemplate, template_type: template_type) do
      nil -> get_default_template(template_type)
      template -> template
    end
  end

  @doc """
  Lists all email templates, including default templates for types not yet customized.
  """
  def list_email_templates do
    custom_templates =
      Repo.all(from t in EmailTemplate, order_by: t.template_type)
      |> Enum.into(%{}, fn t -> {t.template_type, t} end)

    EmailTemplate.template_types()
    |> Enum.map(fn type ->
      case Map.get(custom_templates, type) do
        nil -> get_default_template(type)
        template -> template
      end
    end)
  end

  @doc """
  Updates or creates an email template.
  """
  def update_email_template(template_type, attrs) when is_atom(template_type) do
    update_email_template(Atom.to_string(template_type), attrs)
  end

  def update_email_template(template_type, attrs) when is_binary(template_type) do
    attrs = Map.put(attrs, "is_custom", true)

    case Repo.get_by(EmailTemplate, template_type: template_type) do
      nil ->
        %EmailTemplate{template_type: template_type}
        |> EmailTemplate.changeset(attrs)
        |> Repo.insert()

      template ->
        template
        |> EmailTemplate.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Resets a template to its default content.
  """
  def reset_email_template(template_type) when is_atom(template_type) do
    reset_email_template(Atom.to_string(template_type))
  end

  def reset_email_template(template_type) when is_binary(template_type) do
    case Repo.get_by(EmailTemplate, template_type: template_type) do
      nil ->
        {:ok, get_default_template(template_type)}

      template ->
        Repo.delete(template)
        {:ok, get_default_template(template_type)}
    end
  end

  @doc """
  Returns a changeset for tracking email template changes.
  """
  def change_email_template(%EmailTemplate{} = template, attrs \\ %{}) do
    EmailTemplate.changeset(template, attrs)
  end

  @doc """
  Returns the default template struct for a given type.
  """
  def get_default_template(template_type) do
    %EmailTemplate{
      template_type: template_type,
      subject: DefaultTemplates.default_subject(template_type),
      html_body: DefaultTemplates.default_html_body(template_type),
      text_body: DefaultTemplates.default_text_body(template_type),
      variables: EmailTemplate.available_variables(template_type),
      is_custom: false
    }
  end

  # =============================================================================
  # Contract Terms
  # =============================================================================

  @doc """
  Gets the current active contract terms.
  Creates default terms if none exist.
  """
  def get_current_terms do
    case Repo.one(from t in ContractTerm, where: t.is_active == true, order_by: [desc: t.version], limit: 1) do
      nil ->
        # Create default terms
        %ContractTerm{}
        |> ContractTerm.changeset(%{
          content: ContractTerm.default_content(),
          version: 1,
          effective_date: Date.utc_today(),
          is_active: true
        })
        |> Repo.insert!()

      terms ->
        terms
    end
  end

  @doc """
  Gets contract terms by version number.
  """
  def get_terms_by_version(version) do
    Repo.get_by(ContractTerm, version: version)
  end

  @doc """
  Updates the contract terms.
  If content changes, creates a new version automatically.
  """
  def update_terms(attrs) do
    current_terms = get_current_terms()

    current_terms
    |> ContractTerm.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Lists all contract terms versions.
  """
  def list_terms_versions do
    Repo.all(from t in ContractTerm, order_by: [desc: t.version])
  end

  @doc """
  Returns a changeset for tracking contract terms changes.
  """
  def change_contract_terms(%ContractTerm{} = terms, attrs \\ %{}) do
    ContractTerm.changeset(terms, attrs)
  end

  @doc """
  Resets contract terms to default content.
  Creates a new version with default content.
  """
  def reset_terms_to_default do
    update_terms(%{"content" => ContractTerm.default_content()})
  end
end
