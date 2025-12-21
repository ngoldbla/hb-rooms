defmodule Overbooked.Settings.ContractTerm do
  @moduledoc """
  Schema for contract terms and conditions.
  Supports versioning with automatic version increment on content changes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "contract_terms" do
    field :content, :string
    field :version, :integer, default: 1
    field :effective_date, :date
    field :is_active, :boolean, default: true

    timestamps()
  end

  @doc """
  Returns the default contract terms content.
  """
  def default_content do
    """
    <h2>Office Space Rental Agreement</h2>
    <p>By proceeding with this reservation, you agree to the following terms:</p>
    <ol>
      <li><strong>Payment:</strong> Payment is due in full at the time of booking.</li>
      <li><strong>Cancellation:</strong> Cancellations made within 48 hours of the start date are non-refundable.</li>
      <li><strong>Use:</strong> The space must be used in accordance with building rules and regulations.</li>
      <li><strong>Liability:</strong> You are responsible for any damage to the space during your rental period.</li>
    </ol>
    <p>For full terms and conditions, please contact our support team.</p>
    """
  end

  @doc false
  def changeset(term, attrs) do
    term
    |> cast(attrs, [:content, :version, :effective_date, :is_active])
    |> validate_required([:content])
    |> maybe_increment_version()
  end

  @doc """
  Changeset that auto-increments version when content changes.
  Used when updating existing terms.
  """
  def update_changeset(term, attrs) do
    term
    |> cast(attrs, [:content, :is_active])
    |> validate_required([:content])
    |> increment_version_if_content_changed()
  end

  defp maybe_increment_version(changeset) do
    if get_field(changeset, :version) do
      changeset
    else
      put_change(changeset, :version, 1)
    end
  end

  defp increment_version_if_content_changed(changeset) do
    if get_change(changeset, :content) do
      current_version = get_field(changeset, :version) || 0

      changeset
      |> put_change(:version, current_version + 1)
      |> put_change(:effective_date, Date.utc_today())
    else
      changeset
    end
  end
end
