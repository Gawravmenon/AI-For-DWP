# Root Cause Analysis (RCA)

## Incident Title
User login failure and account lockout - `FINBRIDGE\\cthompson`

## Document Control
- Incident date: 2024-03-15
- RCA authored date: 2026-08-07
- Affected user: `FINBRIDGE\\cthompson`
- Primary endpoint: `DESKTOP-FB022` (`10.10.1.88`)
- Additional authentication source observed: `10.10.8.112`
- Resolver group: DWP / Helpdesk

## Executive Summary
At approximately 08:44, user `cthompson` experienced login failure due to repeated incorrect password submissions, resulting in account lockout. Evidence confirms a progression from bad-password failures to lockout, followed by continued wrong-password Kerberos pre-auth attempts from a second source (`10.10.8.112`).

Resolution steps were applied to stop credential replay, reset and unlock the account, and clean stale credentials. Service restoration was validated by successful interactive logon at 09:09 from `DESKTOP-FB022`, with no further issues reported.

## Business Impact
- Impact scope: Single user only (`cthompson`).
- Service impact: User could not sign in to workstation/session.
- Start time: ~08:40 (reported), first recorded failures from 08:44.
- End time: 09:09 (verified successful login).
- User-facing effect: Work interruption until account access was restored.

## Incident Timeline (All Times Local)
- 08:44:01 - Security Event 4776 (Audit Failure)
  - Domain credential validation failed.
  - Account: `FINBRIDGE\\cthompson`
  - Error: `0xC000006A` (wrong password)
  - Source workstation: `DESKTOP-FB022`

- 08:44:03 - Security Event 4625 (Audit Failure)
  - Failed logon.
  - Failure reason: Unknown user name or bad password
  - Logon type: 2 (Interactive)
  - Source: `DESKTOP-FB022`

- 08:44:28 - Security Event 4625 (Audit Failure)
  - Same failure pattern (bad password, interactive)
  - Source: `DESKTOP-FB022`

- 08:44:55 - Security Event 4625 (Audit Failure)
  - Same failure pattern (bad password, interactive)
  - Source: `DESKTOP-FB022`

- 08:44:56 - Security Event 4740 (Audit Failure)
  - User account locked out.
  - Account: `FINBRIDGE\\cthompson`
  - Caller computer: `DESKTOP-FB022`

- 08:45:10 - Security Event 4625 (Audit Failure)
  - Failed logon after lockout.
  - Failure reason: Account locked out
  - Logon type: 7 (Unlock attempt)
  - Source: `DESKTOP-FB022`

- 08:45:44 - Security Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed.
  - Account: `FINBRIDGE\\cthompson`
  - Failure code: `0x18` (wrong password)
  - Source IP: `10.10.8.112`

- 08:46:01 - Security Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed (`0x18` wrong password)
  - Source IP: `10.10.8.112`

- 08:46:33 - Security Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed (`0x18` wrong password)
  - Source IP: `10.10.8.112`

- 09:08:14 - Security Event 4722 (Audit Success)
  - User account enabled.
  - Account: `FINBRIDGE\\cthompson`
  - Action by: `FINBRIDGE\\helpdesk-admin`

- 09:09:01 - Security Event 4624 (Audit Success)
  - Successful account logon.
  - Account: `FINBRIDGE\\cthompson`
  - Logon type: 2 (Interactive)
  - Source: `DESKTOP-FB022`

- 09:09 - Service restoration confirmed
  - User verified able to log in to host and reported no issues.

## Supporting Evidence and Interpretation
1. Wrong password before lockout is explicit.
- Event 4776 at 08:44:01 with `0xC000006A` confirms incorrect password presented to domain validation.

2. Repeated local interactive failures escalated to lockout.
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 from `DESKTOP-FB022` indicates repeated bad password attempts.
- Event 4740 at 08:44:56 confirms lockout threshold reached.

3. Post-lockout attempts persisted.
- Event 4625 at 08:45:10 (`Account locked out`) confirms lockout state blocked further attempts.

4. Additional credential replay source existed.
- Event 4771 at 08:45:44, 08:46:01, and 08:46:33 from `10.10.8.112` indicates continued wrong-password Kerberos attempts from a different source than `DESKTOP-FB022`.

5. Resolution effectiveness is evidenced by enablement plus successful login.
- Event 4722 at 09:08:14 (account enabled by helpdesk-admin).
- Event 4624 at 09:09:01 (successful interactive login from `DESKTOP-FB022`).

## Root Cause Statement
Primary root cause:
- Account `FINBRIDGE\\cthompson` became locked due to repeated wrong password submissions.

Contributing factor:
- Ongoing stale/incorrect credential replay was observed from an additional authentication source (`10.10.8.112`), increasing risk of immediate relock and complicating recovery.

## 5-Why Analysis
1. Why could the user not log in?
- Because the account was in a locked-out state.
- Evidence: Event 4740 at 08:44:56 and Event 4625 (Account locked out) at 08:45:10.

2. Why was the account locked out?
- Because multiple failed authentication attempts with wrong password occurred in short succession.
- Evidence: Event 4776 at 08:44:01 (`0xC000006A`) and Event 4625 at 08:44:03/08:44:28/08:44:55.

3. Why were wrong passwords repeatedly submitted?
- Because one or more endpoints/processes were supplying stale/incorrect credentials.
- Evidence: failures from both `DESKTOP-FB022` and source IP `10.10.8.112` (Event 4771 sequence).

4. Why did stale credentials continue to replay after lockout?
- Because at least one secondary source/process continued automatic auth attempts using old credentials.
- Evidence: post-lockout Event 4771 failures at 08:45:44/08:46:01/08:46:33 from `10.10.8.112`.

5. Why did this become a user-impacting incident instead of self-correcting quickly?
- Because credential replay and account state required coordinated service desk actions (credential reset/cleanup and account enable/unlock) before successful access could be restored.
- Evidence: account administration action Event 4722 at 09:08:14 and successful login only at 09:09:01.

## Resolution Actions Performed
- Investigated failed auth and lockout events for `cthompson`.
- Applied account remediation (enable/unlock workflow via helpdesk-admin).
- Executed credential hygiene/remediation steps to prevent immediate relock.
- Validated user interactive logon success on primary host.

## Recovery Validation
- Technical validation: Event 4624 success at 09:09:01 (interactive logon from `DESKTOP-FB022`).
- User validation: user confirmed sign-in success and no further issues at 09:09.

## Preventive Actions
1. Credential Replay Source Control
- Identify and remediate source `10.10.8.112` owner/process (scheduled task, service, mapped drive, app profile, or script).
- Ensure credentials are updated/removed to stop background retries.
- Owner: EUC/Identity Operations.
- Priority: High.

2. Lockout Monitoring and Alerting
- Implement alert for repeated 4771/4776 bursts for a single user over short windows.
- Trigger proactive support ticket before lockout threshold is reached.
- Owner: SOC/Monitoring.
- Priority: High.

3. Standardized Lockout Runbook
- Enforce sequence: stop replay source -> reset credentials -> unlock/enable -> validate login.
- Add checklist item for multi-source verification (host + source IP mapping).
- Owner: Service Desk Lead.
- Priority: Medium.

4. User Credential Hygiene Guidance
- Provide one-page user guidance for post-password-change updates across all devices/apps.
- Include VPN, Outlook/Teams, mobile mail, mapped drives, and cached credentials.
- Owner: End User Support.
- Priority: Medium.

5. Periodic Review of Service Accounts/Tasks Using User Credentials
- Audit scheduled tasks/services running under user identities and migrate where feasible.
- Reduce risk of silent bad-password replay.
- Owner: Platform Engineering.
- Priority: Medium.

## Residual Risk
- If source `10.10.8.112` is not fully remediated, future password changes may recreate lockout conditions.

## Closure Note
Incident resolved at 09:09 with verified successful user logon and no immediate recurrence observed.