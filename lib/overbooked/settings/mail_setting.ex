defmodule Overbooked.Settings.MailSetting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mail_settings" do
    field :adapter, :string, default: "mailgun"
    field :mailgun_api_key, :string
    field :mailgun_domain, :string
    field :from_email, :string
    field :from_name, :string, default: "Hatchbridge Rooms"
    field :enabled, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(mail_setting, attrs) do
    mail_setting
    |> cast(attrs, [:adapter, :mailgun_api_key, :mailgun_domain, :from_email, :from_name, :enabled])
    |> validate_required_when_enabled()
    |> validate_format(:from_email, ~r/@/, message: "must be a valid email address")
  end

  defp validate_required_when_enabled(changeset) do
    if get_field(changeset, :enabled) do
      changeset
      |> validate_required([:mailgun_api_key, :mailgun_domain, :from_email, :from_name],
          message: "is required when email is enabled")
    else
      changeset
    end
  end

  @doc """
  Encodes the API key for storage (Base64).
  """
  def encode_api_key(nil), do: nil
  def encode_api_key(api_key), do: Base.encode64(api_key)

  @doc """
  Decodes the API key from storage.
  """
  def decode_api_key(nil), do: nil
  def decode_api_key(encoded_key) do
    case Base.decode64(encoded_key) do
      {:ok, key} -> key
      :error -> encoded_key  # Return as-is if not encoded (for backwards compat)
    end
  end
end
