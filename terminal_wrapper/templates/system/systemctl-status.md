# Template: systemctl-status

Command class: `systemctl status <service>`

Prefer:

```bash
systemctl show <service>
systemctl status <service> --no-pager
```

## Compact render

```text
Service summary
- unit: <service>
- active: <active>
- substate: <substate>
- since: <time>
- main pid: <pid>

Recent signals
- restart count: <n>
- failure reason: <short>

Metadata
- formatter: system/systemctl-status
- mode: compact
```
