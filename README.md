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

### Host AtomVM smoke test

Run a small AtomVM `eunit` smoke `.avm` on host AtomVM to exercise the AtomVM-compatible HTTP path without KR260 hardware:

```bash
make -C packages/micro_scaffold_example host-atomvm-smoke
```

The smoke test executes:

```text
GET /
GET /index2.html

MicroPhoenix.Request.parse
-> MicroPhoenix.Registry.fetch_router
-> MicroScaffoldExampleWeb.Router.route
-> MicroPhoenix.Response.build
```

`/index2.html` also exercises the scaffold item list and template rendering path with AtomVM's compile-time seed data. It is useful for catching AtomVM-incompatible Elixir constructs such as unsupported `String.*` or interpolation paths before trying the KR260 bare-metal build. It does not cover the bare-metal lwIP socket backend or PL Ethernet path.

On AtomVM, `persistent_term` is not available. The smoke test may print:

```text
Unable to open persistent_term.beam
Failed load module: persistent_term.beam
```

This is acceptable if the command also reports zero failures and prints:

```text
- 2 Tests 0 Failures 0 Ignored OK
{micro_scaffold_host_atomvm_smoke,ok}
```

### `/index3.html` on AtomVM

Proxies `http://192.168.1.17:8000/index3.html` via `Req.get`. On AtomVM, `Req` uses **`gen_tcp`** (not ExTCP raw sockets). Start an upstream HTTP server on the host PC/WSL side before testing:

```bash
# example upstream on host PC/WSL (separate terminal)
python3 -m http.server 8000 --bind 0.0.0.0 --directory /path/with/index3.html
```

If upstream is down, `/index3.html` returns **HTTP 502**.

Host BEAM still uses **ExTCP** and needs `cap_net_raw` (see above).

## Endpoints

| Method | Path | Host BEAM | AtomVM |
|--------|------|-----------|--------|
| GET | `/`, `/index.html` | Demo page | Demo page |
| GET | `/api/status` | Status JSON | Status JSON |
| GET | `/index2.html` | Items (PostgreSQL) | 5 seeded items |
| GET | `/index3.html` | Proxied via `Req` (ExTCP) | Proxied via `Req` (gen_tcp) |
