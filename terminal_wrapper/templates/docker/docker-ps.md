# Template: docker-ps

Command class: `docker ps`

Preferred machine-readable source:

```bash
docker ps --format '{{json .}}'
```

## Compact render

```text
Docker summary
- containers: <n>
- running: <n>
- exposed host ports: <n>

Containers
1. <name>
   image: <image>
   status: <status>
   ports: <port summary>

Metadata
- formatter: docker/docker-ps
- mode: compact
- source: format
- omitted: <n>
- truncated: yes|no
```

## Key fields
- Names
- Image
- Status
- Ports
- Command short form

## Do not do
- Do not infer app health from `Up`
- Do not dump full command unless full mode
