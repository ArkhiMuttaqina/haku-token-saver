# Template: docker-images

Command class: `docker images`

Preferred source:

```bash
docker images --format '{{json .}}'
```

## Compact render

```text
Docker image summary
- images: <n>
- dangling: <n>
- total displayed size: <size>

Images
1. <repository>:<tag>
   id: <id>
   size: <size>
   created: <age>

Signals
- dangling images: <n>
- very large images: <list>

Metadata
- formatter: docker/docker-images
- mode: compact
```
