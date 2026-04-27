defmodule MicroScaffoldExample.Repo do
  @app :micro_scaffold_example

  def db_name, do: config(:db_name)
  def db_user, do: config(:db_user)
  def db_pass, do: config(:db_pass)
  def db_host, do: config(:db_host)

  def env, do: [{"PGPASSWORD", db_pass()}]

  defp config(key), do: Application.get_env(@app, key)

  @doc """
  -A   : Aligned出力無効化
  -F , : 区切り文字を「,」に指定
  -t   : カラムなし
  """
  def base_cmd do
    ~w(-h #{db_host()} -U #{db_user()} -d #{db_name()} -A -F , -t -c)
  end

  @doc """
  sqlを実行するが、返り値を利用しない
  """
  def exec(sql) do
    cmd = base_cmd() ++ ["#{sql};"]
    System.cmd("psql", cmd, env: env())
  end

  @doc """
  sqlを実行して返り値を利用する
  psqlによるCSVフォーマットを利用する
  """
  def query(sql, queryable) do
    cmd = base_cmd() ++ ["\\COPY (#{sql}) TO STDOUT WITH CSV HEADER"]

    {output, exit_code} = System.cmd("psql", cmd, env: env())

    case exit_code do
      0 ->
        ret =
          output
          |> :binary.split("\n", [:global, :trim])
          |> to_struct(queryable)

        {:ok, ret}

      _ ->
        {:error, output}
    end
  end

  def one(sql, queryable) do
    case query(sql, queryable) do
      {:ok, ret} -> {:ok, hd(ret)}
      other -> other
    end
  end

  def escape_value(val) when is_integer(val), do: Integer.to_string(val)

  def escape_value(val) when is_binary(val) do
    val
    |> :binary.replace("'", "''", [:global])
    |> then(&"'#{&1}'")
  end

  def all(queryable, _opts \\ []) do
    source = queryable.__schema__(:source)

    {:ok, ret} =
      "SELECT * FROM #{source}"
      |> query(queryable)

    ret
  end

  def get!(queryable, id, _opts \\ []) do
    source = queryable.__schema__(:source)

    {:ok, ret} =
      "SELECT * FROM #{source} WHERE id = #{id}"
      |> one(queryable)

    ret
  end

  def get(queryable, id, _opts \\ []) do
    source = queryable.__schema__(:source)

    case "SELECT * FROM #{source} WHERE id = #{id}"
         |> query(queryable) do
      {:ok, [item | _]} -> item
      _ -> nil
    end
  end

  def insert(struct, attrs) do
    source = struct.__meta__.source

    columns_sql =
      attrs
      |> Map.keys()
      |> Enum.join(", ")

    values_sql =
      attrs
      |> Map.values()
      |> Enum.map(&escape_value(&1))
      |> Enum.join(", ")

    "INSERT INTO #{source} (#{columns_sql}) VALUES (#{values_sql}) RETURNING *"
    |> one(struct)
  end

  def update(struct, attrs \\ %{}) do
    source = struct.__meta__.source

    set_clause =
      attrs
      |> Enum.map(fn {k, v} ->
        "#{k} = #{escape_value(v)}"
      end)
      |> Enum.join(", ")

    "UPDATE #{source} SET #{set_clause} WHERE id = #{struct.id} RETURNING *"
    |> one(struct)
  end

  def delete(struct) do
    source = struct.__meta__.source

    {output, exit_code} =
      "DELETE FROM #{source} WHERE id = #{struct.id}"
      |> exec()

    case exit_code do
      0 ->
        {:ok, struct(struct.__struct__)}

      _ ->
        {:error, output}
    end
  end

  defp to_struct(rows, queryable) do
    [header | data_rows] = rows

    keys =
      header
      |> :binary.split([","], [:global])
      |> Enum.map(&:erlang.binary_to_atom(&1, :utf8))

    Enum.map(data_rows, fn row ->
      values = :binary.split(row, [","], [:global])
      zipped = Enum.zip(keys, values)

      Enum.into(zipped, %{}, fn
        {:id, val} -> {:id, :erlang.binary_to_integer(val)}
        {k, val} -> {k, val}
      end)
    end)
    |> Enum.map(&struct(queryable, &1))
  end
end
