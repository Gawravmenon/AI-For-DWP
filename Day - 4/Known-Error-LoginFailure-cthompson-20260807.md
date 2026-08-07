# Known Error Record - DWP KB

Symptom: User FINBRIDGE\cthompson could not sign in on DESKTOP-FB022 during the morning incident window. After lockout, a further attempt showed the account locked message in security logs.

Cause: The verified root cause was account lockout triggered by repeated incorrect password submissions for FINBRIDGE\cthompson. A contributing factor was continued wrong-password credential replay from a second source, 10.10.8.112.

Scope: This incident affected one user only: FINBRIDGE\cthompson. Systems observed in evidence were DESKTOP-FB022 (10.10.1.88) and a second authentication source at 10.10.8.112.

Workaround: Restore service by following the lockout recovery sequence used in the incident: complete account recovery actions (enable/unlock), stop stale credential replay, then retry sign-in. In this case, account recovery was performed at 09:08:14 and successful interactive sign-in was confirmed at 09:09:01 from DESKTOP-FB022.

Permanent fix: Remediate the credential replay source by identifying and correcting the owning process or asset behind 10.10.8.112 so old credentials are no longer submitted. Add monitoring for repeated 4771/4776 bursts to enable earlier intervention before lockout.

How to spot it: Look for this event sequence: Event 4776 with error 0xC000006A (wrong password), repeated Event 4625 failures (including "Unknown user name or bad password" and later "Account locked out"), and Event 4740 account lockout. Confirm secondary replay with Event 4771 failure code 0x18 (wrong password) from source IP 10.10.8.112, then confirm recovery with Event 4722 followed by Event 4624 interactive logon success.