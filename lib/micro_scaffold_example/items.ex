defmodule MicroScaffoldExample.Items do
  alias MicroScaffoldExample.Items.Item
  alias MicroScaffoldExample.Repo

  def list_items do
    Repo.all(Item)
  end

  def create_item(name) when is_binary(name) do
    create_item(%{name: name})
  end

  def create_item(attrs) when is_map(attrs) do
    %Item{}
    |> Repo.insert(attrs)
  end

  def delete_item(id) when is_integer(id) do
    case Repo.get(Item, id) do
      nil -> {:error, :not_found}
      item -> Repo.delete(item)
    end
  end
end
