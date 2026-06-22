# MicroScaffoldExample

A scaffold example application built on top of MicroPhoenix.

The app can run on **host BEAM** (`mix run`) or **AtomVM** (`./bin/atomvm-run`).
Both use port 8080 — do not run them at the same time.

## Usage

```bash
mix deps.get
mix run --no-halt
```

The server will start on http://localhost:8080/

## Required permissions for Req/ExTCP

`Req.get` uses raw socket access through ExTCP.  
If `:eperm` occurs, grant `cap_net_raw` to `beam.smp`:

```bash
ERL_ROOT=$(erl -noshell -eval 'io:format("~s",[code:root_dir()]), halt().')
sudo setcap cap_net_raw+ep "$ERL_ROOT"/erts-*/bin/beam.smp
getcap "$ERL_ROOT"/erts-*/bin/beam.smp
```

Expected output includes:

```text
.../beam.smp cap_net_raw=ep
```

If you see `_build/... permission denied`, fix ownership:

```bash
sudo chown -R "$(id -un)":"$(id -gn)" _build
```

## Create test data

Before starting the server, you can create 5 sample `Items.Item` records with:

```bash
mix run -e "Enum.each(MicroScaffoldExample.Seed.names(), fn name -> MicroScaffoldExample.Items.create_item(name) end)"
```

Requires PostgreSQL and `psql`. See `config/config.exs` for connection settings.

## AtomVM

Build and run on [AtomVM](https://github.com/atomvm/AtomVM):

```bash
export ATOMVM_INSTALL_PREFIX=/path/to/AtomVM/build
export PATH="$ATOMVM_INSTALL_PREFIX/src:$PATH"

mkdir -p avm_deps   # must be empty
mix deps.get
mix atomvm.packbeam
./bin/atomvm-run
```

`bin/atomvm-run` loads stdlib AVMs (`atomvmlib`, `estdlib`, `exavmlib`) together with the app.

On AtomVM, `/index2.html` lists 5 seeded items (compile-time, same names as host).
`/index3.html` returns HTTP 503. Database and `Req` are host-only for now.

## Endpoints

| Method | Path | Host BEAM | AtomVM |
|--------|------|-----------|--------|
| GET | `/`, `/index.html` | Demo page | Demo page |
| GET | `/api/status` | Status JSON | Status JSON |
| GET | `/index2.html` | Items (PostgreSQL) | 5 seeded items |
| GET | `/index3.html` | Proxied via `Req` | HTTP 503 |

