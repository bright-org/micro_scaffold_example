defmodule MicroScaffoldExample.Repo do
  @moduledoc """
  Repo facade. Delegates to PostgreSQL (`psql`) on host BEAM or in-memory on AtomVM.
  """

  @atomvm_key :micro_scaffold_atomvm_repo
  @configured_backend Application.compile_env(:micro_scaffold_example, :repo_backend, :process)

  def all(queryable, opts \\ []), do: apply(backend(), :all, [queryable, opts])
  def get(queryable, id, opts \\ []), do: apply(backend(), :get, [queryable, id, opts])
  def get!(queryable, id, opts \\ []), do: apply(backend(), :get!, [queryable, id, opts])
  def insert(struct, attrs), do: apply(backend(), :insert, [struct, attrs])
  def update(struct, attrs \\ %{}), do: apply(backend(), :update, [struct, attrs])
  def delete(struct), do: apply(backend(), :delete, [struct])

  def mark_atomvm_repo do
    :erlang.put(@atomvm_key, true)
  end

  defp backend do
    case @configured_backend do
      :process ->
        process_backend()

      backend ->
        backend
    end
  end

  defp process_backend do
    case :erlang.get(@atomvm_key) do
      true -> MicroScaffoldExample.Repo.AtomVM
      _ -> MicroScaffoldExample.Repo.Postgres
    end
  catch
    :error, :undef -> MicroScaffoldExample.Repo.Postgres
  end
end
