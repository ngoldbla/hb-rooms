defmodule Overbooked.Resources.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resources" do
    field :name, :string
    field :color, :string, default: "gray"
    field :booking_count, :integer, virtual: true

    # Rentable space pricing fields
    field :is_rentable, :boolean, default: false
    field :monthly_rate_cents, :integer
    field :description, :string
    field :capacity, :integer, default: 1

    has_many :bookings, Overbooked.Schedule.Booking
    has_many :contracts, Overbooked.Contracts.Contract

    many_to_many :amenities, Overbooked.Resources.Amenity,
      join_through: Overbooked.Resources.ResourceAmenity,
      on_replace: :delete

    belongs_to :resource_type, Overbooked.Resources.ResourceType
    timestamps()
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :color, :is_rentable, :monthly_rate_cents, :description, :capacity])
    |> validate_required([:name, :color])
    |> validate_number(:capacity, greater_than: 0)
    |> validate_rentable_pricing()
  end

  @doc """
  Validates that rentable resources have a monthly rate set.
  """
  defp validate_rentable_pricing(changeset) do
    is_rentable = get_field(changeset, :is_rentable)
    monthly_rate = get_field(changeset, :monthly_rate_cents)

    if is_rentable && (is_nil(monthly_rate) || monthly_rate <= 0) do
      add_error(changeset, :monthly_rate_cents, "is required for rentable spaces")
    else
      changeset
    end
  end

  def put_resource_type(
        %Ecto.Changeset{} = changeset,
        %Overbooked.Resources.ResourceType{} = resource_type
      ) do
    put_assoc(changeset, :resource_type, resource_type)
  end

  def put_amenities(
        %Ecto.Changeset{} = changeset,
        amenities
      ) do
    put_assoc(changeset, :amenities, amenities)
  end
end

