# Root Cause Analysis - RDP Account Lockout
**Incident Reference:** INC-20240315-RDP-BWALKER  
**Date of Incident:** 2024-03-15  
**Analysis Window:** 14:01:02 - 14:22:09 (within reported 30-minute impact window)  
**Affected User:** bwalker (FINBRIDGE domain)  
**Affected Endpoint / Source Client:** 10.10.5.44  
**Affected Access Method:** Remote Desktop Protocol (RDP) / RemoteInteractive logon  
**Document Author:** DWP Analyst  
**Date of RCA:** 2026-08-07

---

## 1. Incident Summary

User `FINBRIDGE\bwalker` was unable to access the target system over RDP during the incident window. The supplied System and Security logs show an initial RDP protocol/security-layer disconnect, followed by repeated failed RemoteInteractive logons from source IP `10.10.5.44` using an incorrect username/password combination. After the third failed authentication, Active Directory locked the account. A later connection from the same client IP succeeded, indicating the account was subsequently unlocked or the lockout duration expired and the user then supplied the correct password.

---

## 2. What Each Event ID Records

### Event ID 56 (Source: TermDD, Level: Error)
Records that the Terminal Services security layer detected a problem in the RDP protocol/security stream and disconnected the client session.

In this incident, because Event 56 occurs at the same time as an RDP authentication failure (Event 140), it is most likely the disconnect generated when the session could not proceed through the security/authentication stage, rather than evidence of a separate network outage.

### Event ID 140 (Source: RemoteDesktopServices-RdpCoreTS, Level: Warning)
Records that an RDP connection attempt failed because the supplied user name or password was incorrect.

In this incident, it ties the failed authentication to client IP `10.10.5.44` at `14:01:02`.

### Event ID 4625 (Security, Level: Audit Failure)
Records a failed logon attempt. The event includes the account used, the failure reason, the logon type, and the source address.

In this incident, each Event 4625 records:
- Account: `FINBRIDGE\bwalker`
- Failure reason: `Unknown username or bad password`
- Logon type: `10` (`RemoteInteractive`, used by RDP/Remote Desktop)
- Source IP: `10.10.5.44`

This confirms the failures were RDP sign-in attempts from the same client.

### Event ID 4740 (Security, Level: Audit Failure)
Records that a user account was locked out.

In this incident, Event 4740 confirms `FINBRIDGE\bwalker` was locked out at `14:05:34`, and attributes the lockout-triggering source to caller computer `10.10.5.44`.

### Event ID 131 (Source: RemoteDesktopServices-RdpCoreTS, Level: Information)
Records that the server accepted a new inbound TCP connection from an RDP client.

This only confirms network/session initiation at the transport layer. It does not mean authentication succeeded.

### Event ID 4624 (Security, Level: Audit Success)
Records a successful logon.

In this incident, Event 4624 shows `FINBRIDGE\bwalker` successfully completed a `Logon type 10` (`RemoteInteractive`) sign-in from `10.10.5.44` at `14:22:09`.

---

## 3. Timeline of Events

| Time | Event ID | Type | Description |
|------|----------|------|-------------|
| 14:01:02 | 56 | Error | RDP security/protocol stream error causes client disconnect |
| 14:01:02 | 140 | Warning | RDP authentication fails because username/password is incorrect |
| 14:01:04 | 4625 | Audit Failure | First failed RemoteInteractive logon for `FINBRIDGE\\bwalker` from `10.10.5.44` |
| 14:03:18 | 4625 | Audit Failure | Second failed RemoteInteractive logon from same source |
| 14:05:33 | 4625 | Audit Failure | Third failed RemoteInteractive logon from same source |
| 14:05:34 | 4740 | Audit Failure | Account lockout triggered for `FINBRIDGE\\bwalker`; caller computer `10.10.5.44` |
| 14:22:07 | 131 | Information | Server accepts a new TCP connection from `10.10.5.44:52341` |
| 14:22:09 | 4624 | Audit Success | Successful RemoteInteractive logon for `FINBRIDGE\\bwalker` from `10.10.5.44` |

---

## 4. Reconstructed Sequence of Events (Plain English)

1. At `14:01`, the user at `10.10.5.44` starts an RDP connection.
2. The connection reaches the server, but authentication fails because the supplied credentials are not accepted. The RDP session is then dropped during the security/authentication stage.
3. Two more RDP logon attempts are made from the same client over the next four minutes, and both fail with the same `Unknown username or bad password` result.
4. Immediately after the third failed RDP sign-in, the domain account `FINBRIDGE\bwalker` is locked out. The lockout event names `10.10.5.44` as the caller computer that triggered it.
5. No successful logon occurs during the failed-attempt window, so the user remains unable to use the remote application/system because the account is locked.
6. At `14:22`, the same client IP connects again. This time the TCP connection is accepted and, two seconds later, the account successfully logs on over RDP.
7. This indicates the lockout had been cleared by then, either through administrative unlock or lockout-duration expiry, and the user used the correct password on the final attempt.

---

## 5. Most Likely Cause of the Lockout

### Most likely cause
The lockout was caused by repeated RDP authentication attempts from `10.10.5.44` using an incorrect password for `FINBRIDGE\bwalker`, which exceeded the domain account lockout threshold.

### Evidence from events
- Event `140` at `14:01:02` explicitly states the RDP connection failed because the username or password was not correct.
- Three Event `4625` entries at `14:01:04`, `14:03:18`, and `14:05:33` all show the same account, same failure reason, same logon type (`10`), and same source IP (`10.10.5.44`).
- Event `4740` occurs one second after the third `4625`, proving the failed attempts from `10.10.5.44` directly caused the lockout.
- Event `4624` at `14:22:09` from the same source IP shows the user later authenticated successfully, which supports the conclusion that the earlier failures were incorrect credential submissions rather than a persistent network or RDP service failure.

### Most probable operational interpretation
The pattern is more consistent with the user manually retrying an incorrect password, or an RDP client using a stale saved credential, than with a server-side service outage:
- the failures are spaced apart rather than occurring in a rapid burst,
- the failure reason remains credential-related throughout,
- and the same source later succeeds without any evidence of server remediation in the supplied logs.

---

## 6. Five-Why Analysis

### Problem statement
User `FINBRIDGE\bwalker` was unable to access the remote system/application over RDP because the account became locked during repeated failed sign-in attempts from `10.10.5.44`.

### Why 1: Why was the user unable to use the remote application/system?
Because the RDP session could not be established successfully during the incident window and the account was locked.

Evidence: repeated Event `4625` failures followed by Event `4740`.

### Why 2: Why did the RDP session fail repeatedly?
Because the username/password presented during RemoteInteractive logon attempts was rejected as invalid.

Evidence: Event `140` and all three Event `4625` entries state incorrect credentials / bad password.

### Why 3: Why were invalid credentials submitted multiple times?
The most likely explanation is either manual re-entry of the wrong password by the user or reuse of a stale saved RDP credential from the client at `10.10.5.44`.

Evidence: three spaced failed logons from the same client, then later success from the same client once the lockout condition had cleared.

### Why 4: Why did three failed attempts result in user impact this severe?
Because the domain lockout policy was configured so that the number of failed RDP logons reached the lockout threshold before the user corrected the credential issue.

Evidence: Event `4740` immediately follows the third Event `4625`.

### Why 5: Why did the incident require waiting until `14:22` for successful access?
Because once the lockout was triggered, the user could not authenticate again until the account was unlocked or the lockout duration elapsed.

Evidence: there are no successful logons between `14:05:34` and `14:22:09`; the next authentication from the same source is successful only after that gap.

---

## 7. Root Cause Statement

The direct root cause was three consecutive failed RDP logon attempts using invalid credentials for `FINBRIDGE\bwalker` from client `10.10.5.44`, which triggered the domain account lockout policy.

The most likely underlying trigger was either user password entry error or a stale saved RDP credential on the source client. The supplied logs do not prove which of those two caused the invalid submissions, but they do clearly show that credential failure, not network failure, caused the lockout.

---

## 8. Corrective and Preventive Actions

1. Confirm whether `10.10.5.44` had saved RDP credentials for `FINBRIDGE\bwalker` and clear/update them if present.
2. Ask the user whether the password had recently changed and whether they were manually typing or using stored credentials.
3. Review account lockout policy threshold and duration to ensure it balances brute-force protection with operational tolerance for normal user error.
4. Add a first-line support check for Credential Manager / saved RDP credentials in future RDP lockout incidents.
5. If not already available, consider self-service unlock/reset controls to reduce user downtime after accidental lockout.

---

## 9. Residual Risks

- If a saved credential remains on `10.10.5.44`, the lockout may recur.
- If the lockout threshold is low, normal user typing errors will continue to generate avoidable access incidents.
- The supplied logs identify the source and cause category clearly, but they do not prove whether the bad password came from manual input, stored credentials, or another process running under the user's context on the same client.

---

## 10. Sign-off

| Role | Name | Date |
|------|------|------|
| DWP Analyst |  |  |
| Service Desk Lead |  |  |
| AD / Identity Team |  |  |