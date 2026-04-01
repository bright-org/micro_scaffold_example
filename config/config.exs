import Config

config :micro_scaffold_example,
  ecto_repos: [MicroScaffoldExample.Repo]

config :micro_scaffold_example, MicroScaffoldExample.Repo,
  database: "priv/repo/dev.sqlite3",
  pool_size: 2
