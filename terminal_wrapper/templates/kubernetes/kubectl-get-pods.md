# Template: kubectl-get-pods

Command class: `kubectl get pods -A`

Preferred source:

```bash
kubectl get pods -A -o wide
```

## Compact render

```text
Kubernetes pod summary
- namespaces: <n>
- pods: <n>
- healthy: <n>
- restarting: <n>
- pending: <n>
- failed: <n>

Notable pods
1. <namespace>/<pod>
   status: <status>
   restarts: <n>
   node: <node>

Metadata
- formatter: kubernetes/kubectl-get-pods
- mode: compact
```

## Key signals
- CrashLoopBackOff
- ImagePullBackOff
- Pending
- high restart count
