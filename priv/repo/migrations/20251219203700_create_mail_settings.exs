defmodule Overbooked.Repo.Migrations.CreateMailSettings do
  use Ecto.Migration

  def change do
    create table(:mail_settings) do
      add :adapter, :string, default: "mailgun"
      add :mailgun_api_key, :string
      add :mailgun_domain, :string
      add :from_email, :string
      add :from_name, :string, default: "Hatchbridge Rooms"
      add :enabled, :boolean, default: false

      timestamps()
    end

    # Ensure only one row exists (singleton pattern)
    create unique_index(:mail_settings, [:id], name: :mail_settings_singleton, where: "id IS NOT NULL")
  end
end
