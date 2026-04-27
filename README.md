# MicroScaffoldExample

A scaffold example application built on top of MicroPhoenix.

## Usage

```bash
mix deps.get
mix run --no-halt
```

## Routes

- `http://localhost:8080/` or `http://localhost:8080/index.html` — Returns a static HTML page defined as a constant in the controller. The page includes a button to call `GET /api/status`.
- `http://localhost:8080/index2.html` — Fetches all records from the `items` table via mini_ecto and returns an HTML page listing each item name.
- `http://localhost:8080/index3.html` — Proxies an external server via `Req.get/2` and returns the HTML response from `http://localhost:8000/index3.html`.

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
mix run -e "alias MicroScaffoldExample.Items; Enum.each(1..5, fn i -> Items.create_item(\"Sample Item #{i}\") end)"
```

