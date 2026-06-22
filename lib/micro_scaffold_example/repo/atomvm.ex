defmodule MicroScaffoldExample.Repo.AtomVM do
  @moduledoc """
  Read-only in-memory Repo for AtomVM.

  AtomVM does not provide ETS (`tab2list`, etc.), `Process`, or `persistent_term`.
  Items are seeded at compile time; CRUD mutators return success without persisting.
  """

  alias MicroScaffoldExample.Items.Item

  @seed_names ~w(Apple Banana Cherry Date Elderberry)

  @items Enum.with_index(@seed_names, 1)
         |> Enum.map(fn {name, id} -> %Item{id: id, name: name} end)

  def all(_queryable, _opts \\ []), do: @items

  def get(_queryable, id, _opts \\ []) do
    Enum.find(@items, &(&1.id == id))
  end

  def get!(queryable, id, opts \\ []) do
    case get(queryable, id, opts) do
      nil -> raise "item not found"
      row -> row
    end
  end

  def insert(struct, attrs) do
    id = length(@items) + 1
    row = struct(struct, Map.put(attrs, :id, id))
    {:ok, row}
  end

  def update(struct, attrs \\ %{}) do
    {:ok, struct(struct, attrs)}
  end

  def delete(struct) do
    {:ok, struct}
  end
end
