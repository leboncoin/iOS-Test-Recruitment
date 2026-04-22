# API Server

A local Vapor server that powers the iOS technical test.

## Requirements

- macOS 13+
- Swift 5.9+

## Run

```bash
swift run
```

The server starts on `http://localhost:8080`.

## Test

```bash
swift test
```

## Endpoints

See `swagger.yaml` for the full API contract.

Notes:

- `GET /listings` always returns a feed envelope with `items`, `total`, `page`, `limit`, and `has_more`
- listings are sorted with urgent items first, then by descending creation date
- `page` and `limit` must be used together
- image URLs in the seed data are local fixture assets served by the API server
