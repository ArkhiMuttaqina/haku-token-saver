# Template: pytest

Command class: `pytest`

Use `pytest --tb=short` or junit xml.

## Compact render

```text
Test summary
- passed: <n>
- failed: <n>
- warnings: <n>
- duration: <time>

Failed
1. <test>
   file: <file>
   error: <short>

Warnings
- <warning message>

Metadata
- formatter: python/pytest
- mode: compact
```

## Key signals
- FAILED or ERROR
- flaky rerun
- warning summary