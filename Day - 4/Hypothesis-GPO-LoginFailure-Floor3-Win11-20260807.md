# Hypothesis Analysis — Group Policy Login Failure | Floor 3 Win11 Machines

**Date:** 2026-08-07  
**Analyst:** DWP Engineer  
**Client:** Client C  
**Status:** Evidence reviewed — hypotheses assessed, root cause not yet formally committed

---

## Scope Facts

| Field | Detail |
|---|---|
| Symptom | Group Policy issues causing login failure |
| Affected machines | 3 × Windows 11 workstations, Floor 3 only |
| Who | Client C |
| Onset | ~07:40 this morning |
| Reported changes | Nil |

---

## Key Diagnostic Constraints

- **Geographic scope** (floor 3 only) points toward shared network infrastructure or a subnet/VLAN boundary.
- **Multiple machines affected simultaneously** rules out a single machine fault.
- **No reported change** does not eliminate a change — scheduled tasks, automated patching, or an unreported infrastructure event at ~07:40 remain in scope.
- **Login failure via GP** typically means the machine cannot reach a DC to apply policy, or policy itself is broken/inaccessible.

---

## Ranked Hypothesis List

> Ranked most probable first. No single cause is committed to at this stage.

---

### 1. Floor 3 Network Segment / VLAN Loss of DC Connectivity

**Why this fits:**  
The failure is confined exclusively to floor 3. This is the strongest indicator of a shared network-layer fault — a floor switch, VLAN, or trunk port serving floor 3 may have degraded or lost the path to the domain controllers. Without DC connectivity, Kerberos authentication fails and Group Policy cannot be applied, producing login failure.

**Fastest single check:**  
From an affected machine (or via remote PS if accessible):
```powershell
nltest /dsgetdc:domain.local
```
If this fails or returns a DC on a different site, confirm floor 3 switch/VLAN health in the network management console.

---

### 2. DNS Resolution Failure on Floor 3

**Why this fits:**  
Group Policy processing and domain login depend entirely on DNS to locate domain controllers and SYSVOL. If floor 3 machines have a separate DNS server (e.g. a local/secondary DNS at the floor or subnet level) and that server became unavailable at ~07:40, all three machines would silently fail to resolve DC names — producing GP failure and login issues while appearing as a "GP problem" rather than a DNS problem.

**Fastest single check:**  
```powershell
Resolve-DnsName -Name domain.local -Type SRV
```
Run on an affected machine. A timeout or NXDOMAIN confirms DNS is the path to follow.

---

### 3. GPO Linked to Floor 3 OU Modified or Corrupted

**Why this fits:**  
If the three machines are in a dedicated Floor 3 or Building/Location OU in Active Directory, a GPO specifically linked to that OU could have been modified by an automated process, a scheduled AD maintenance task, or an unreported admin action overnight — taking effect at the next GP refresh cycle (which aligns with ~07:40 logon time). Corruption of a GPO's SYSVOL template folder also causes processing failure.

**Fastest single check:**  
Open GPMC on a DC → sort all GPOs by **Last Modified** → check for any GPO modified after business hours yesterday or early this morning. Also run:
```powershell
gpresult /r /scope computer
```
on an affected machine to see which GPOs are failing and what error codes are returned.

---

### 4. SYSVOL / Netlogon Replication Failure on the Authenticating DC

**Why this fits:**  
Floor 3 machines may preferentially authenticate against a specific DC (e.g. one physically or logically closest to floor 3). If SYSVOL replication (DFS-R) has broken down on that DC, machines can authenticate via Kerberos but fail to retrieve GP templates from `\\domain\SYSVOL`, causing Group Policy processing to fail. This would affect only the machines hitting the unhealthy DC — explaining the floor-3-only scope.

**Fastest single check:**  
From an affected machine:
```powershell
net use \\<DC-name>\SYSVOL
```
Then on the DC itself:
```powershell
dfsrdiag ReplicationState
```
An inaccessible share or replication backlog confirms this path.

---

### 5. Machine Secure Channel Broken (Machine Account Issue)

**Why this fits:**  
If the three floor 3 machines share a common provisioning history (same image deployment date, same OU join date), their machine account Kerberos secure channel could have expired or broken simultaneously. A broken secure channel prevents the machine from authenticating to the domain — causing GP failure and login issues. The simultaneous onset on three machines suggests a common trigger (e.g. all three hit a 30-day account password rotation at the same time).

**Fastest single check:**  
```powershell
Test-ComputerSecureChannel -Verbose
```
A `False` result on one or more machines confirms a broken channel. If confirmed, remediate with:
```powershell
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)
```

---

---

## Evidence Assessment — Event Log Review (DESKTOP-FB031, 07:40–07:55)

> Evidence source: System Event Log, DESKTOP-FB031. Comparison machine: DESKTOP-FB029 (same OU, unaffected).

---

### Important Pre-Assessment Note — "Change: Nil" Discrepancy

The scope facts stated no change. The event log evidence reveals an **unreported infrastructure change**: a DNS migration wave decommissioned the Floor 3 local DNS server (`10.10.3.250` / `172.16.5.5`) at **02:00** on the incident date. The DHCP scope for the Floor 3 subnet was not updated to point to the replacement DNS server (`10.10.0.10`). This change was not reported by Client C. This context is critical to all judgements below.

---

### H1 — Floor 3 Network Segment / VLAN Loss of DC Connectivity

**Verdict: CONTRADICTED**

The network layer is demonstrably healthy. `Event 7036 (07:40:02)` confirms the Network Location Awareness service entered running state — the machine had a functional network path. `DHCP Event 50036 (07:42:18)` shows a successful IP lease from `10.10.0.1`, proving IP-layer connectivity to the rest of the network. FB029 also received a DHCP lease and successfully processed Group Policy at `07:40:11`. The DC unreachability reported in `Event 5719 (07:40:08)` is explicitly attributed to a DNS resolution failure (`DNS query for FINBRIDGE-DC01.finbridge.local returned no response`), not a network path failure.

| Event ID | Time | Role in judgement |
|---|---|---|
| 7036 (SCM) | 07:40:02 | Network is up — contradicts layer-2/3 fault |
| 50036 (DHCP) | 07:42:18 | Successful IP lease — contradicts VLAN failure |
| 5719 (Netlogon) | 07:40:08 | Explicitly blames DNS, not network |

---

### H2 — DNS Resolution Failure on Floor 3

**Verdict: STRONGLY SUPPORTED — leading hypothesis**

Every evidence chain converges here.

- `Event 5719 (07:40:08)`: Netlogon cannot set up a secure channel because `DNS query for FINBRIDGE-DC01.finbridge.local returned no response`.
- `Event 1014 (07:41:05)`: DNS Client confirms name resolution timed out and `none of the configured DNS servers responded`.
- `DHCP Event 50036 (07:42:18)`: The machine received DNS server `10.10.3.250` — confirmed as the **old, decommissioned DNS server** taken offline at 02:00.
- DHCP server logs confirm all affected machines (FB055–FB057) received the stale DNS entry from the un-updated DHCP scope.
- FB029 (unaffected) received `10.10.0.10` (correct DNS) and processed Group Policy successfully at `07:40:11`.

The geographic scope is explained by the DHCP scope being subnet-specific to Floor 3. The single unaffected machine (FB029/FB058) was manually pre-configured before the migration wave.

| Event ID | Time | Role in judgement |
|---|---|---|
| 5719 (Netlogon) | 07:40:08 | DNS query failure named as direct cause |
| 1014 (DNS Client) | 07:41:05 | No DNS server responded |
| 50036 (DHCP) | 07:42:18 | Wrong DNS server assigned — decommissioned at 02:00 |
| 1500 (GP, FB029) | 07:40:11 | Unaffected machine with correct DNS succeeds |

---

### H3 — GPO Linked to Floor 3 OU Modified or Corrupted

**Verdict: CONTRADICTED**

`Event 1058 (07:40:09 and 07:40:11)` reports that the SYSVOL path `\\FINBRIDGE-DC01\sysvol\...\gpt.ini` cannot be accessed with error `0x3` (path not found). This superficially resembles GPO corruption, but `0x3` in this context means the UNC path resolution failed because the DC hostname could not be resolved — DNS never returned an address for `FINBRIDGE-DC01`. The error is a downstream consequence of H2, not evidence of a corrupted or modified GPO. FB029, with correct DNS, successfully accessed the same SYSVOL and processed the same GPO at `07:40:11`, confirming the GPO itself is intact.

| Event ID | Time | Role in judgement |
|---|---|---|
| 1058 (GP) | 07:40:09 | 0x3 error = path unreachable due to DNS, not GPO corruption |
| 1500 (GP, FB029) | 07:40:11 | Same GPO processes successfully on machine with correct DNS |

---

### H4 — SYSVOL / DFS-R Replication Failure on the Authenticating DC

**Verdict: CONTRADICTED**

`Event 1058` shows SYSVOL is inaccessible, which is consistent with DFS-R failure. However, FB029 successfully connects to and reads from `\\FINBRIDGE-DC01\sysvol` at `07:40:11` — using the same DC. This directly proves the DC's SYSVOL share and DFS-R replication are healthy. The affected machines cannot reach SYSVOL only because they cannot resolve the DC hostname (H2). If DFS-R were the fault, FB029 would also have failed.

| Event ID | Time | Role in judgement |
|---|---|---|
| 1058 (GP) | 07:40:09 | SYSVOL inaccessible — but cause is DNS, not replication |
| 1500 (GP, FB029) | 07:40:11 | Same DC's SYSVOL accessed successfully — eliminates DFS-R fault |

---

### H5 — Machine Secure Channel Broken (Machine Account Issue)

**Verdict: CONTRADICTED**

`Event 5719 (07:40:08)` is the classic secure channel failure event and initially appears to support this hypothesis. However, the event message explicitly states the reason: `no domain controller available` and `DNS query for FINBRIDGE-DC01.finbridge.local returned no response`. A genuine machine account / secure channel fault produces Event 5719 with a different cause — the DC is found but authentication is rejected (e.g. `Access denied` or `The trust relationship... has failed`). Here, the machine never even reaches the DC to attempt authentication. Event 5719 is a downstream effect of H2.

| Event ID | Time | Role in judgement |
|---|---|---|
| 5719 (Netlogon) | 07:40:08 | Secure channel fails but stated cause is DNS — not machine account rejection |

---

## Evidence Summary Table

| Hypothesis | Verdict | Determining Event(s) |
|---|---|---|
| H1 — VLAN / Network failure | **Contradicted** | 7036 (07:40:02), 50036 (07:42:18) — network is healthy |
| H2 — DNS failure (Floor 3 stale DNS via DHCP) | **Strongly Supported** | 5719 (07:40:08), 1014 (07:41:05), 50036 (07:42:18) |
| H3 — GPO corrupted / modified | **Contradicted** | 1058 0x3 error is DNS-downstream; FB029 1500 confirms GPO intact |
| H4 — SYSVOL / DFS-R failure | **Contradicted** | FB029 1500 (07:40:11) — same DC's SYSVOL healthy |
| H5 — Secure channel / machine account | **Contradicted** | 5719 cause is DNS resolution, not account rejection |

---

## Next Steps

1. **Immediate remediation:** Update the DHCP scope for the Floor 3 subnet (`10.10.3.x`) to replace DNS server `10.10.3.250` / `172.16.5.5` with `10.10.0.10`. Force DHCP lease renewal on affected machines (`ipconfig /release` then `/renew`).
2. **Verify resolution:** Re-run `nltest /dsgetdc:finbridge.local` and `gpupdate /force` on FB031 after DNS correction.
3. **Change management review:** Raise a post-incident finding — the DNS migration change was not recorded in the change log presented to the support team, and the DHCP scope update was missed as a dependency.
4. **Formal RCA:** H2 is sufficiently supported to proceed to root cause documentation once remediation confirms recovery.

---

## Related Files

- [Hypothesis-LoginFailure-cthompson-20260807.md](Hypothesis-LoginFailure-cthompson-20260807.md)
- [Triage-AVD-BlackScreen-Incident-Hypothesis-20260807.md](Triage-AVD-BlackScreen-Incident-Hypothesis-20260807.md)
