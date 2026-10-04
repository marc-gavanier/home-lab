# ADR-037 — An allowlisting socket proxy, because "read-only" read every file

**Status**: accepted — 2026-10-04
**Depends on**: ADR-016 (secrets as files), ADR-023 (Dozzle on the socket proxy)
**Related**: ADR-019 (read-only rootfs), ADR-030 (configure the tools, do not write the glue)

## Context

ADR-016 moved every password out of `Env` and into files under `/run/secrets/`,
on the premise that the socket proxy's `CONTAINERS=1` grant exposes `Env` and
nothing else. The premise was false. `tecnativa/docker-socket-proxy` grants by
path prefix: `CONTAINERS=1` allows every `GET` under `/containers`, including
`/containers/{id}/archive` (the `docker cp` endpoint) and `/containers/{id}/export`.
Measured on 2026-10-04: from the netdata container, a `HEAD` on
`/containers/vaultwarden/archive?path=/run/secrets/...` answered 200 with the
file's size and mode, while `/volumes` answered 403. Traefik, Netdata or Dozzle,
once compromised, could read the 17 secret files of 14 containers and every data
volume.

The image offers no flag finer than the prefix. Denying the two paths meant
replacing its rules file with a copy of our own, which drifts from the image the
day it changes. Rejected for that reason.

## Decision

Replace it with **`wollomatic/socket-proxy`**, whose documented options take an
allowlist of regular expressions per HTTP method, anchored, matched on the path.
Everything not listed is refused.

- `GET`: `_ping`, `version`, `info`, `events`, `images/json`, `containers/json`,
  and `containers/{id}/` `json`, `logs`, `stats`. That is the union of what the
  three consumers sent over six hours of live traffic, plus Dozzle's `logs` and
  `stats`, exercised on a throwaway pair.
- `HEAD`: `_ping`. No other method.
- `-allowfrom` is the `socketproxy` network's subnet, now pinned in compose from
  `docker_expected_subnets` so the two cannot disagree.
- It runs as `65534` with the host's `docker` group, `read_only`, and its own
  healthcheck binary, which checks the socket behind the proxy.

## Consequences

**Positive**
- `archive`, `export`, `changes`, `attach`, `top`, `/networks` and `/volumes` answer
  403, measured on the throwaway pair. The posture check
  `socket-proxy-refuses-file-reads` asserts the refusal live, with `/_ping` as its
  control.
- socket-proxy joins the read-only containers, which the old image could not.

**Negative / cost**
- A consumer that needs a new endpoint gets 403 until the allowlist names it; the
  proxy logs each refusal as `blocked request` with the path.
- Pinning the subnet recreated the network once, with every container on it.

## Alternatives considered

- **Our own copy of the old image's rules file**, one deny line added. Drifts from
  the image. Rejected by the operator.
- **Accept the risk and correct ADR-016.** It needs a compromised consumer first,
  but the fix costs one service definition.
