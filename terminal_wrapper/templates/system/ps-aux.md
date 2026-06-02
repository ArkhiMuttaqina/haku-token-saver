# Template: ps-aux

Command class: `ps aux`

Prefer process subset queries. Use filters.

## Compact render

```text
Process summary
- total: <n>
- top cpu user: <user>
- top cpu proc: <pid>/<comm>
- top mem proc: <pid>/<comm>

Notable
- high CPU (>50%)
- zombie
- long-running

Metadata
- formatter: system/ps-aux
- mode: compact
```

## Use filters first
`hts -- ps aux | grep <pattern>` is cheaper.

Template used for overview only.