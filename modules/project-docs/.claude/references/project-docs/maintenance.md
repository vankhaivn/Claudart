# Update, audit, and compact

Use [ownership](ownership.md) to identify the current owner before editing or judging a claim. Inspect only affected topics and their routes first; expand to a broader audit when the request or the observed disorder calls for it. A session, checkpoint, or small code edit alone does not trigger a full docs audit.

## Update on an actual doc impact

When an approved decision, behavior, public contract, supported version, setup, or operating procedure changes, identify the claims it affects. Check approval for intent and source or release evidence for actual behavior. Edit each topic's owner and dependent router/link/brief summary within the authorized scope. A task or spec should invoke this work only when its change affects what current docs say; it can conclude there is no doc impact. Keep proposal and execution details in the work record, not a second roadmap in docs.

For a release, update the current capability/version and operating instructions that the release evidence supports. Keep older supported versions accurate. This module does not deploy, tag, publish, or coordinate a release.

Keep established page shapes when they serve their readers. If the change exposes a missing responsibility or an unsuitable page, select the relevant [output template](templates.md); do not convert unrelated owners. Approved requirements, observed implementation, and supported releases may advance at different times. Once a pending change is evidenced in its applicable scope, replace that scope's current claim and remove the now-redundant pending summary. Keep detailed delivery evidence in the work/release owner.

## Audit: report evidence and a repair path

Audit is read-only when the user asks for a review. Check the relevant router and owners for broken/orphan routes, two current owners for one fact, claims that contradict source or approved decisions, stale proposal presented as active intent, unshipped behavior presented as released, and task history filling current guidance. Distinguish demonstrated errors from missing evidence and open product decisions. Provide file/topic-specific findings, the evidence, impact, and a proposed keep/rewrite/merge/retire action. Do not infer that old dates, long files, or untracked files are obsolete.

## Compact or fix: perform the authorized cleanup

When the user asks to fix, reconcile, or compact, make the scoped edits without a new per-file approval gate. Define the replacement owner and affected links before removing duplicate prose. Keep current facts, distinct scopes, supported versions, and still-useful rationale; retire superseded guidance only when approval and evidence establish that it no longer applies. History belongs in existing Git/release/work records unless a decision record has ongoing value. Do not automatically archive a copy after each change.

Preserve original inputs, untracked files, custom docs, and team/external sources unless the user's permission actually covers their modification or deletion. If authority remains ambiguous, leave the disputed material intact and state the decision needed. After edits, check changed links and relevant project validation, inspect the diff for accidental loss, and report remaining uncertainty. Knowledge changes must follow the selected runtime's knowledge maintenance reference and checker.
