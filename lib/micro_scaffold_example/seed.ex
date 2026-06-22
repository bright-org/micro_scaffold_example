defmodule MicroScaffoldExample.Seed do
  @moduledoc """
  Sample item names shared by host BEAM (PostgreSQL seed command) and AtomVM (compile-time items).
  """

  @names ~w(Apple Banana Cherry Date Elderberry)

  def names, do: @names

  def build_items do
    alias MicroScaffoldExample.Items.Item

    @names
    |> Enum.with_index(1)
    |> Enum.map(fn {name, id} -> %Item{id: id, name: name} end)
  end
end
