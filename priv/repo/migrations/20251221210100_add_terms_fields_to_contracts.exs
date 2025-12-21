defmodule Overbooked.Repo.Migrations.AddTermsFieldsToContracts do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add :accepted_terms_version, :integer
      add :terms_accepted_at, :utc_datetime
    end
  end
end
