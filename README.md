# deploy-template

Helm library chart: cách một workload divket được render thành resource k8s.
Phiên bản hiện tại: `0.1.0` (xem `Chart.yaml`).

## Dùng ở dự án khác

Chart được publish lên GHCR (public):

```
oci://ghcr.io/divket/deploy-template
```

Khai dependency trong `Chart.yaml` của chart dự án:

```yaml
dependencies:
  - name: deploy-template
    version: 0.1.0
    repository: oci://ghcr.io/divket
```

Rồi:

```sh
helm dependency update .
helm template demo .   # máy nào cũng render được, không cần checkout repo này
```

`Chart.lock` của dự án commit vào git — đó là nơi duy nhất pin phiên bản deploy-template.
Đổi version template là bump `version` ở dependency rồi `helm dependency update` lại.

## Helpers (`_common.tpl`, `_env.tpl`, `_health.tpl`)

Mọi helper nhận đúng một dict `(dict "ctx" $ "name" <workload>)`,
không đọc `.Values` trực tiếp.

| Helper | Đọc | Ra |
|---|---|---|
| `deploy-template.fullname` | release + name | `<release>-<name>`, cắt 63 ký tự |
| `deploy-template.selectorLabels` | — | đúng 2 nhãn, immutable, không bao giờ thêm |
| `deploy-template.labels` | workload kind | selectorLabels + component + managed-by |
| `deploy-template.image` | registry, workload image, `$w.tag` (default `image.tag`) | `<registry>/<image>:<tag>` |
| `deploy-template.podSecurity` | workload podSecurity (default chart) | securityContext pod |
| `deploy-template.containerSecurity` | — | `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem`, `drop ALL` (non-root via `podSecurity`) |
| `deploy-template.resources` | workload resources | khối resources (caller guard rỗng) |
| `deploy-template.env` | workload env + top-level dependencies | env[]; dependency → `<ENV>=<service>.<ns>.svc.cluster.local:<port>` |
| `deploy-template.envFrom` | workload envFrom | secretRef + configMapRef |
| `deploy-template.probes` | workload health {port, ready, live, startup} | readiness/liveness/startupProbe; rỗng thì không render |

## Kinds

| Kind | Template | Ra |
|---|---|---|
| backend | `_backend.tpl` | Deployment + Service ClusterIP; đủ trường spec |
| frontend | `_frontend.tpl` | như backend, port default 80, không probe |
| worker | `_worker.tpl` | chỉ Deployment, không Service/ports/probe |
| stateful | `_stateful.tpl` | StatefulSet + volumeClaimTemplates (`volume` `{size, storageClass, mountPath}` (template treats as optional — absent means no `volumeClaimTemplates`; production stateful should set it)) + headless Service |

## Singleton (`_migration.tpl`, `_route.tpl`)

- `migration` đọc `.Values.migration {enabled, image, tag, command, envFrom}`;
  Job hook pre-upgrade/pre-install, chỉ additive (§10 spec).
- `route` đọc `.Values.routes[] {path, workload, protocol, hostname}` +
  `.Values.gateway {name, namespace}`; http → HTTPRoute PathPrefix,
  grpc → GRPCRoute với `method.service` = tên workload (quy ước;
  spec không cho service/method riêng). Tên resource
  `<release>-<workload>-<index>` để không trùng.

## NetworkPolicy (`_networkpolicy.tpl`)

Một policy mỗi workload, chỉ render khi `.Values.dependencies` non-empty.
Egress mở theo cặp namespace+port (chart không biết label pod dependency);
DNS về kube-system:53; ingress từ `gateway.namespace` (default `platform`).

## Test

```sh
./tests/run.sh
```

Render từng fixture trong `tests/fixtures/` qua harness chart rồi so với
golden trong `tests/golden/`. Đổi template mà output đổi thì test đỏ, buộc
phải cập nhật golden có chủ ý bằng `UPDATE_GOLDEN=1 ./tests/run.sh`.

Yêu cầu **helm v4** (v4 append `\n` vào output rỗng) và `yq` v4 (mikefarah).

## Harness test và quy ước đồng bộ

`tests/harness/values.yaml` phải mirror mọi default top-level của
`values.yaml` (trừ `workloads`) vì Helm chỉ merge default của library chart
vào `.Values["deploy-template"]`, còn helper đọc top-level qua `.ctx`.
`tests/run.sh` tự check điều này và FAIL nếu lệch — đổi default thì sửa cả hai.

## Publish version mới

```sh
# 1. Bump version trong Chart.yaml
# 2. Merge vào main (chỉ chạy lint + test)
# 3. Đánh tag chart-vX.Y.Z để CI publish:
git tag chart-v0.2.0 && git push origin chart-v0.2.0
```

CI publish: `helm package .` + `helm push` lên `oci://ghcr.io/divket`.
Không push đè cùng version (OCI immutable) — mỗi version publish một lần.
Lần publish đầu tiên cần vào GitHub package chuyển visibility sang public
để repo org khác pull được mà không cần token.
