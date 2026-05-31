# Caveman Adaptation

Official Caveman is not treated here as the core CLI filtering backend.

## Key Decision

Official Caveman focuses more on:
- compressed agent response style
- terse command/report patterns
- config/memory compression ideas
- optional workflow helpers

This repo uses those ideas selectively.

## What We Borrow

### 1. Terse response policy
Use short, technical, low-filler output for:
- status reports
- command summaries
- validation results
- small bugfix explanations

### 2. Template-style summaries
Use stable workflow templates for:
- git status
- git log
- lint summaries
- test summaries
- npm scripts listing

### 3. Compression mindset
Apply compression to:
- terminal summaries
- config guidance
- reusable agent instructions

## What We Do Not Borrow

- full installer ecosystem
- large preset bundles
- many unrelated skills
- generic dependency on Caveman as command wrapper backend
- full feature parity with upstream Caveman repo

## Architecture Fit

In this repo:

```text
snip  -> preferred generic backend
rtk   -> fallback generic backend
raw   -> no filtering
```

Template mode is separate:

```text
scripts/caveman_wrapper.sh
```

So Caveman is a policy/template layer, not a backend in the fallback chain.

## Why

Reason:
- cleaner architecture
- less coupling to upstream preset behavior
- easier debugging
- lower skill/config bloat risk
- keeps raw mode and generic backends explicit

## Practical Rule

Use:

```bash
haku-token-saver -- git status
```

for generic command routing.

Use:

```bash
haku-token-saver --template git-status
```

for curated stable summaries.

Do not describe template mode as automatic CLI filtering fallback.