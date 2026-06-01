# Template: ss-listen

Command class: `ss -tulpn` or `ss -ltnp`

## Compact render

```text
Listening sockets
- tcp: <n>
- udp: <n>
- public binds: <n>
- localhost binds: <n>

Ports
1. <addr>:<port>
   proto: <tcp|udp>
   process: <name/pid>

Signals
- public bind 0.0.0.0 or ::
- privileged port

Metadata
- formatter: system/ss-listen
- mode: compact
```
