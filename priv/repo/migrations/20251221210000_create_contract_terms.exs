defmodule Overbooked.Repo.Migrations.CreateContractTerms do
  use Ecto.Migration

  def change do
    create table(:contract_terms) do
      add :content, :text, null: false
      add :version, :integer, null: false, default: 1
      add :effective_date, :date
      add :is_active, :boolean, default: true

      timestamps()
    end

    create index(:contract_terms, [:version])
    create index(:contract_terms, [:is_active])
  end
end
