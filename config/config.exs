import Config

repo_backend =
  case System.get_env("MICRO_SCAFFOLD_REPO_BACKEND") do
    "atomvm" -> MicroScaffoldExample.Repo.AtomVM
    _ -> :process
  end

index3_url =
  System.get_env("MICRO_SCAFFOLD_INDEX3_URL") ||
    "http://192.168.1.17:8000/index3.html"

config :micro_phoenix,
  port: 5000,
  listen_options: [{:inet_backend, :socket}],
  router: {MicroScaffoldExampleWeb.Router, :route}

config :micro_scaffold_example,
  repo_backend: repo_backend,
  index3_url: index3_url,
  db_name: "micro_scaffold_example_dev",
  db_user: "postgres",
  db_pass: "postgres",
  db_host: "localhost"
