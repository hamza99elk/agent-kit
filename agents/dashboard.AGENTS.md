# rratatouille — signal-only personal dashboard

A terminal UI dashboard powered by [tui-dashboard](https://github.com/lyuangg/tui-dashboard) (Go binary) that renders real-time data from shell scripts.

## Project structure

```
/Users/pro/hamza-workspace/dashboard/
├── config.yaml           # Layout + source definitions
├── scripts/              # Shell scripts — one per data source
└── .pi/skills/           # pi-agent skills
```

## Commands

- `just dash` — run the dashboard
- `just dash-reload` — restart with updated config (ctl-c + `just dash`)
- `cd scripts && ./<script>.sh` — test a single source script directly

## Source format reference

| Type | Output format | Example |
|------|---------------|---------|
| `map` | `key: value` per line | `nw_usd: 882958` |
| `array` | one value per line | `23326\n287328\n496484` |
| `timeseries` | `<unix_seconds> <value>` | `1763942400 8686` |
| `table` | tab-separated with header | `account\\tbalance\\tcurrency` |

## Widget style guide (finances section)

- **Bar chart**: prefer `style: solid` over `hbar` (cleaner, no ░░ headroom)
- **Chart**: prefer `style: dots` for monthly data (braille line + bold ● per month)
- **Runway**: prefer `gauge` over stat (visual progress bar, min 0 / max 60)
- **Labels**: must match script output order exactly — DB `ORDER BY entity` gives `llc, personal, sarl`
- **Width**: omit `width:` to let widgets expand elastically; never use `%'` in printf (not supported)

## Section colors (Dracula theme)

| Section | Hex |
|---------|-----|
| Habits | `#50fa7b` |
| Tasks | `#8be9fd` |
| Finances | `#ffb86c` |
| Nutrition | `#bd93f9` |
| Body | `#ff5555` |
| Exercise | `#f1fa8c` |

## Finance DB

SQLite at `~/hamza-workspace/finances/ledger.db`. View `v_dashboard` is the main aggregator — 13 columns covering cash, burn, net worth per entity in both USD and MAD.