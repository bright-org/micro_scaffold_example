defmodule MicroScaffoldExample.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    timestamps()
  end

end
