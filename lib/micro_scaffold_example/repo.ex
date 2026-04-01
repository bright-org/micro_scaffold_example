defmodule MicroScaffoldExample.Repo do
  use Ecto.Repo,
    otp_app: :micro_scaffold_example,
    adapter: Ecto.Adapters.SQLite3
end
