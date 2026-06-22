defmodule MicroScaffoldExample.Repo do
  @moduledoc """
  Repo facade. Delegates to PostgreSQL (`psql`) on host BEAM or in-memory on AtomVM.
  """

  @atomvm_key :micro_scaffold_atomvm_repo

  def all(queryable, opts \\ []), do: backend().all(queryable, opts)
  def get(queryable, id, opts \\ []), do: backend().get(queryable, id, opts)
  def get!(queryable, id, opts \\ []), do: backend().get!(queryable, id, opts)
  def insert(struct, attrs), do: backend().insert(struct, attrs)
  def update(struct, attrs \\ %{}), do: backend().update(struct, attrs)
  def delete(struct), do: backend().delete(struct)

  def mark_atomvm_repo do
    :erlang.put(@atomvm_key, true)
  end

  defp backend do
    case :erlang.get(@atomvm_key) do
      true -> MicroScaffoldExample.Repo.AtomVM
      _ -> MicroScaffoldExample.Repo.Postgres
    end
  catch
    :error, :undef -> MicroScaffoldExample.Repo.Postgres
  end
end
