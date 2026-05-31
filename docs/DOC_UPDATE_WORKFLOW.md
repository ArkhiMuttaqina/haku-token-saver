# HTS Documentation Update Workflow

This is the internal checklist for any change that touches documentation in the hts repo.

## Trigger

Run this workflow when you edit any of these files:

- `README.md`
- `docs/*.md`
- `skills/*/SKILL.md`
- `ARCHITECTURE.md` (if it exists)
- install flow docs or usage guides

Also run when you add, remove, or move any stable documentation.

## Before-commit checklist

- [ ] Spelling and naming is consistent with the rest of the repo
- [ ] Commands and paths are correct and verified
- [ ] Cross-references (links) are accurate
- [ ] No sensitive data is present (secrets, API keys, private paths)
- [ ] Syntax checks pass (bash -n for scripts, linters where applicable)

## After-commit checklist

### 1. Verify commit exists

```bash
git log -1 --oneline
git status --short
```

### 2. Push changes

```bash
git push origin <branch>
```

### 3. Wait for remote acceptance (optional, but good practice)

```bash
git fetch origin
```

### 4. LightRAG sync

Insert the documentation delta into LightRAG. Use this template:

```python
import os, requests, time

base=os.environ.get('LIGHTRAG_URL','http://127.0.0.1:6611')
key=os.environ.get('LIGHTRAG_API_KEY','')
headers={'X-API-Key': key} if key else {}

text="""Project: hts (haku-token-saver) CLI toolkit
Fact: <short summary of what changed>
Decision: <why the change was made, if relevant>
Command: <any install/usage commands that changed>
Pitfall: <new pitfalls introduced or old ones removed>
Verified: <what was tested and the result>
"""

r=requests.post(base+'/documents/text',headers=headers,json={'text':text},timeout=120)
print(r.status_code, r.text[:500])

# Poll pipeline until not busy
for _ in range(30):
    s=requests.get(base+'/documents/pipeline_status',headers=headers,timeout=20).json()
    if not s.get('busy'):
        print('pipeline not busy')
        break
    time.sleep(5)
```

### 5. Verify LightRAG insertion worked

Run a focused query to confirm the new fact is retrievable:

```python
payload={'query':'hts <keyword-from-change>','mode':'hybrid'}
r=requests.post(base+'/query',headers=headers,json=payload,timeout=120)
print(r.status_code, r.text[:1000])
```

Expect the response to mention the new fact.

## Anti-patterns to avoid

- Do not skip LightRAG sync for README changes
- Do not sync temporary scratch notes or TODO lists that will change daily
- Do not sync unverified changes (run tests/smoke checks first)
- Do not paste large chunks of raw documentation; summarize into facts
- Do not forget to poll the pipeline status; the insert is async

## Example post-doc-update command sequence

After you update README.md and push to development:

```bash
git log -1 --oneline                    # commit hash
git push origin development             # push
python - <<'PY'
# insert to LightRAG (see template above)
PY
python - <<'PY'
# verify retrieval (see query template above)
PY
```

## When to skip LightRAG sync

You may skip sync for:

- Minor typo fixes with no semantic change
- Local scratch notes that are not committed
- Very small edits that do not affect usage, install, or behavior
- Changes to `.hermes/` (gitignored) or other temporary local notes

If you skip sync, state clearly in your reply why.
