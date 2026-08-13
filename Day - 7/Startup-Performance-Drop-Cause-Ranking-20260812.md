# Startup Performance Drop - Ranked Likely Causes
Date: 2026-08-12
Scope facts used: Finance-Win11 (215 devices) saw a startup-time and score drop immediately after a Finance-only security baseline configuration profile deployed on 2026-08-04 02:00. IT-Win11 (40 devices) was outside the change and stayed stable.

## 1) New security baseline profile added startup work on Finance-Win11
Why it fits the evidence: The startup drop begins exactly after the Finance-only config change, and the comparison group without the change stayed stable. That makes the new profile itself the strongest match for the timing. Startup script and extra Defender scan policy are both direct candidates for longer logon-to-desktop time.
Fastest check: Compare the deployed profile settings against the pre-change baseline and temporarily test the same device group with the new startup script and Defender policy removed or disabled.

## 2) Startup script added for compliance logging is slowing logon
Why it fits the evidence: The change log specifically calls out a startup script, and the slowdown starts on the same day the script was deployed. A script runs during startup and can delay usable desktop time even if the rest of the system is fine. The unaffected IT group did not receive this change, which supports the script as a Finance-only cause.
Fastest check: Disable the startup script for a small pilot set in Finance-Win11 and measure whether median startup time returns toward the prior range.

## 3) Additional Defender scan policy is extending startup processing
Why it fits the evidence: The config change also added an extra Defender scan policy, which is another Finance-only startup-time candidate. The drop is immediate after deployment and not seen in the comparison group, so a new security workload during startup is more likely than a broad platform issue.
Fastest check: Remove the additional Defender scan policy from a controlled test set, then remeasure startup time and compare against unchanged Finance devices and the stable IT group.
