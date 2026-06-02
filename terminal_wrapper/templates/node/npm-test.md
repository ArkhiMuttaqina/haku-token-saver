# Template: npm-test

Command class: `npm test`

Use tap/junit output when possible.

## Compact render

```text
Test summary
- passed: <n>
- failed: <n>
- skipped: <n>
- duration: <time>

Failed tests
1. <test name>
   file: <file>
   error: <short message>

Metadata
- formatter: node/npm-test
- mode: compact
```

## Key signals
- any failure
- flaky tests
- long duration