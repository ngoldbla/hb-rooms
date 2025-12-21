defmodule Overbooked.Repo.Migrations.CreateEmailTemplates do
  use Ecto.Migration

  def change do
    create table(:email_templates) do
      add :template_type, :string, null: false
      add :subject, :string, null: false
      add :html_body, :text, null: false
      add :text_body, :text
      add :variables, {:array, :string}, default: []
      add :is_custom, :boolean, default: false

      timestamps()
    end

    create unique_index(:email_templates, [:template_type])
  end
end
