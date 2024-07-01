defmodule Ret.Repo.Migrations.AddHubLoggerToHubs do
  use Ecto.Migration

  def change do
    alter table(:hubs) do
      add :allow_hub_logger, :boolean, null: false, default: false
    end
  end

end
