# Formatter Spec

A terminal wrapper formatter converts raw CLI output into structured packets.

## Formatter contract

Input:
- command argv
- raw stdout
- raw stderr
- exit code
- token/detail budget

Output:
- compact text packet
- metadata footer
- fallback note when parsing fails

## Detail modes

### compact
- default for agents
- max important fields only
- group repeated rows

### normal
- more fields
- include short explanations for signals

### full
- keep more raw detail, still structured

## Metadata footer

```text
Metadata
- formatter: <domain>/<name>
- mode: compact
- source: raw|json|format
- exit: 0
- omitted: 0
- truncated: no
```

## Fallback

If parsing fails:

```text
Formatter fallback
- formatter: <name>
- reason: parse-failed
- mode: bounded-raw

<bounded raw output>
```

## Safety

Do not run mutating commands inside formatter logic. Formatters only process outputs or add safe read-only flags.
