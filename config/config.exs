import Config

config :micro_phoenix,
  port: 5000,
  listen_options: [{:inet_backend, :socket}],
  router: {MicroScaffoldExampleWeb.Router, :route}

config :micro_scaffold_example,
  db_name: "micro_scaffold_example_dev",
  db_user: "postgres",
  db_pass: "postgres",
  db_host: "localhost"
