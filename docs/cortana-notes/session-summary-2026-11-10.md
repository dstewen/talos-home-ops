# Session Summary — 2026-11-10

> **Author:** cortananexus-bot[bot]
> **Participants:** dstewen (gateway-owner)
> **Repository:** talos-home-ops

---

## Session Scope

- Review DGX Spark network configuration (management and QSFP ports)
- Evaluate MTU settings against Jory's frecklelabs/k8s reference
- Assess ConnectX-7 fabric configuration needs for DAC-cabled 2-node GPU cluster

---

## DGX Spark Network Review

### Hardware Summary

Each DGX Spark (GB10) has:
- **Management**: Realtek RTL8127 10G copper (`enP7s7`)
- **Fabric**: 2x Mellanox ConnectX-7 QSFP56 (4 ports total across both NICs)
- **Compute**: 128GB unified memory, Blackwell GPU via C2C

### Management Interface (enP7s7)

| Setting | Current | Jory's (fairy-k8s01) | Decision |
|---|---|---|---|
| MTU | 1500 | 9000 | **Leave at 1500 for now** |
| IPs | Static (10.200.15.71/72) | Static (with DHCP for newer nodes) | ✅ Matches |

Cilium derives its cluster MTU from the management link. At 1500, the cluster runs fine for now — jumbo frames (9000) would be an optimization when pod traffic volume warrants it.

### ConnectX-7 Fabric Ports

The 4 QSFP56 ports (`enp1s0f0np0`, `enP2p1s0f0np0`, `enp1s0f1np1`, `enP2p1s0f1np1`) are **not yet configured** in `topf.yaml`.

**Current state**: Left unplugged — nodes communicate via management network only.

**Reference (frecklelabs/k8s)**: Jory configures all 4 ports at MTU 9000 with no host IPs. They are purely layer-2 for NCCL/gpu interconnect.

**DAC cabling**: The 2 DGX Spark nodes are connected directly via a DAC cable, not through a switch. This means:
- No RoCE/PFC configuration needed (no intermediary switch)
- Simple point-to-point topology
- Can assign static IPs on the fabric links when needed

### Multi-Node GPU Clustering (Future)

When multi-node NCCL is needed:
1. Add 4 `LinkConfig` entries to the DGX schematic (MTU 9000, no host IPs)
2. Assign simple static IPs on the fabric (e.g. `10.255.255.0/30` between nodes)
3. No switch configuration required (direct DAC link)

---

## Kernel Configuration

Already correctly set in `talos/topf/main/schematics/dgx.yaml`:

| Setting | Value | Purpose |
|---|---|---|
| `arm64.nobti` | Yes | Prevents crashes and CUDA library load failures |
| `pci=pcie_bus_safe` | Yes | Raises PCIe MaxPayload for NCCL throughput on ConnectX-7 |
| `siderolabs/nonfree-kmod-nvidia-production` | Yes | Proprietary drivers (open-source causes CUDA cuInit error 3) |
| `siderolabs/nvidia-container-toolkit-production` | Yes | Container runtime integration |

---

## Node MAC Addresses (Confirmed)

| Node | Management IP | MAC Address |
|---|---|---|
| spark1 | 10.200.15.71 | `4c:bb:47:ec:9d:9e` |
| spark2 | 10.200.15.72 | `4c:bb:47:ec:9c:99` |

Both MACs are configured in `talos/topf/main/topf.yaml` and IP reservations are set in OPNsense.

---

## Decision Summary

1. **Management MTU**: Leave at 1500 — no immediate need for jumbo frames
2. **ConnectX-7 ports**: Leave unconfigured — no multi-node GPU clustering planned yet
3. **DAC link**: No additional switch/RoCE config needed when the time comes
4. **All configs are clean** — ready for physical bootstrap

---

## Related

- [Codebase Review](./codebase-review.md)
- [MIGRATION_PLAN.md](../../MIGRATION_PLAN.md)
- [Jory's frecklelabs/k8s reference](https://github.com/frecklelabs/k8s)
