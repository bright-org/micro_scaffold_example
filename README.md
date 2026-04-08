# MicroScaffoldExample

A scaffold example application built on top of MicroPhoenix.

## Usage

```bash
mix deps.get
mix run -e "MicroPhoenix.start()" --no-halt
```

The server will start on http://localhost:8080/

## Create test data

Before starting the server, you can create 5 sample `Items.Item` records with:

```bash
mix run -e "alias MicroScaffoldExample.Items; Enum.each(1..5, fn i -> Items.create_item(\"Sample Item #{i}\") end)"
```

