defmodule Overbooked.Settings.EmailTemplate do
  @moduledoc """
  Schema for customizable email templates.
  Allows admins to customize email content with variable substitution.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @template_types ~w(welcome password_reset update_email contract_confirmation contract_cancelled refund_notification)

  schema "email_templates" do
    field :template_type, :string
    field :subject, :string
    field :html_body, :string
    field :text_body, :string
    field :variables, {:array, :string}, default: []
    field :is_custom, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:template_type, :subject, :html_body, :text_body, :variables, :is_custom])
    |> validate_required([:template_type, :subject, :html_body])
    |> validate_inclusion(:template_type, @template_types)
    |> unique_constraint(:template_type)
  end

  @doc """
  Returns the list of valid template types.
  """
  def template_types, do: @template_types

  @doc """
  Returns a human-readable name for a template type.
  """
  def humanize_type("welcome"), do: "Welcome Email"
  def humanize_type("password_reset"), do: "Password Reset"
  def humanize_type("update_email"), do: "Update Email"
  def humanize_type("contract_confirmation"), do: "Contract Confirmation"
  def humanize_type("contract_cancelled"), do: "Contract Cancelled"
  def humanize_type("refund_notification"), do: "Refund Notification"
  def humanize_type(type), do: type |> String.replace("_", " ") |> String.capitalize()

  @doc """
  Returns list of available variables for each template type.
  """
  def available_variables("welcome"), do: ["user.name", "user.email", "url"]
  def available_variables("password_reset"), do: ["user.name", "user.email", "url"]
  def available_variables("update_email"), do: ["user.name", "user.email", "url"]

  def available_variables("contract_confirmation") do
    [
      "user.name",
      "user.email",
      "contract.resource.name",
      "contract.resource.description",
      "contract.start_date",
      "contract.end_date",
      "contract.duration_months",
      "contract.total_amount"
    ]
  end

  def available_variables("contract_cancelled") do
    [
      "user.name",
      "user.email",
      "contract.resource.name",
      "contract.start_date",
      "contract.end_date"
    ]
  end

  def available_variables("refund_notification") do
    [
      "user.name",
      "user.email",
      "contract.resource.name",
      "contract.refund_amount",
      "contract.refund_id"
    ]
  end

  def available_variables(_), do: []

  @doc """
  Returns a description of the template purpose.
  """
  def description("welcome"), do: "Sent when a new user registers or is invited"
  def description("password_reset"), do: "Sent when a user requests a password reset"
  def description("update_email"), do: "Sent when a user changes their email address"
  def description("contract_confirmation"), do: "Sent when a contract payment is completed"
  def description("contract_cancelled"), do: "Sent when a contract is cancelled"
  def description("refund_notification"), do: "Sent when a refund is processed"
  def description(_), do: ""
end
