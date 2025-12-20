defmodule Overbooked.Settings.StripeSetting do
  @moduledoc """
  Schema for Stripe payment configuration.
  Uses the singleton pattern - only one row exists in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "stripe_settings" do
    field :enabled, :boolean, default: false
    field :secret_key, :string
    field :publishable_key, :string
    field :webhook_secret, :string
    field :environment, :string, default: "test"

    timestamps()
  end

  @doc false
  def changeset(stripe_setting, attrs) do
    stripe_setting
    |> cast(attrs, [:enabled, :secret_key, :publishable_key, :webhook_secret, :environment])
    |> validate_required_when_enabled()
    |> validate_key_formats()
  end

  defp validate_required_when_enabled(changeset) do
    if get_field(changeset, :enabled) do
      changeset
      |> validate_required([:secret_key, :webhook_secret],
          message: "is required when Stripe is enabled")
    else
      changeset
    end
  end

  defp validate_key_formats(changeset) do
    changeset
    |> validate_secret_key_format()
    |> validate_publishable_key_format()
    |> validate_webhook_secret_format()
    |> validate_inclusion(:environment, ["test", "live"])
  end

  defp validate_secret_key_format(changeset) do
    case get_field(changeset, :secret_key) do
      nil -> changeset
      "" -> changeset
      key ->
        # Allow masked keys (contain ****)
        if String.contains?(key, "****") do
          changeset
        else
          # Validate actual key format
          if String.starts_with?(key, "sk_test_") or String.starts_with?(key, "sk_live_") do
            changeset
          else
            add_error(changeset, :secret_key, "must start with sk_test_ or sk_live_")
          end
        end
    end
  end

  defp validate_publishable_key_format(changeset) do
    case get_field(changeset, :publishable_key) do
      nil -> changeset
      "" -> changeset
      key ->
        if String.starts_with?(key, "pk_test_") or String.starts_with?(key, "pk_live_") do
          changeset
        else
          add_error(changeset, :publishable_key, "must start with pk_test_ or pk_live_")
        end
    end
  end

  defp validate_webhook_secret_format(changeset) do
    case get_field(changeset, :webhook_secret) do
      nil -> changeset
      "" -> changeset
      key ->
        # Allow masked keys (contain ****)
        if String.contains?(key, "****") do
          changeset
        else
          if String.starts_with?(key, "whsec_") do
            changeset
          else
            add_error(changeset, :webhook_secret, "must start with whsec_")
          end
        end
    end
  end

  @doc """
  Encodes a secret key for storage (Base64).
  """
  def encode_key(nil), do: nil
  def encode_key(""), do: nil
  def encode_key(key), do: Base.encode64(key)

  @doc """
  Decodes a secret key from storage.
  """
  def decode_key(nil), do: nil
  def decode_key(""), do: nil
  def decode_key(encoded_key) do
    case Base.decode64(encoded_key) do
      {:ok, key} -> key
      :error -> encoded_key  # Return as-is if not encoded (for backwards compat)
    end
  end
end
