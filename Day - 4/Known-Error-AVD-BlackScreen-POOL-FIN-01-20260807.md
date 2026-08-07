Symptom: Users in POOL-FIN-01 saw a black or blank screen after AVD sign-in from about 07:00. For some users it cleared after about 30 seconds; for others it persisted and could lead to disconnect/reconnect behavior.

Cause: Verified root cause was an image-introduced Intel display driver regression on POOL-FIN-01. It caused dwm.exe to crash in igdumd64.dll during post-login desktop composition.

Scope: Approximately 40% of users assigned to POOL-FIN-01 were affected. POOL-FIN-02 was not updated overnight and remained unaffected.

Workaround: During impact, keep user access on unaffected POOL-FIN-02 while remediation is performed on POOL-FIN-01. This restores service availability while preventing new exposure on the affected pool.

Permanent fix: Apply the approved display driver/image corrective action to return POOL-FIN-01 to the known-good display baseline (rollback/hotfix path), then restart/remediate impacted hosts. Service recovery was verified at 10:00 with successful logins and no new issue reports.

How to spot it: On affected POOL-FIN-01 hosts, look for Application Error Event 1000 showing dwm.exe faulting in igdumd64.dll (version 31.0.101.4146) with exception 0xc0000005, and Desktop Window Manager Event 9009 (DWM exited with code 0x40010004). In the same sequence, Event 21 logon success is followed by Event 40 disconnect; unaffected comparison hosts show DWM Event 9011 and no matching Event 1000 in the incident window.
