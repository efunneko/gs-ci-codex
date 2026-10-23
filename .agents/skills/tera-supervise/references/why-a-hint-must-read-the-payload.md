# Why a hint must read the payload

`§4.2`'s first row outranks every row below it, and this page is why: the two
ways a budget kill reaches you, the one place the message that identifies it is
composed, and the retry hint that got the diagnosis wrong with the evidence
attached to the very event it was written on.

Two facts make it so, and each on its own would be enough. A dispatch **killed
at its deadline** and a tool that merely **exited non-zero** both arrive as
`exit_error` with no `failure.kind` at all. And a budget kill does not even
reliably arrive under that code: the common path reports `exit_error`
(`pkg/extension/executor.go`, where a signalled child surfaces as an ordinary
negative exit with no error), while the exec-error seam and the credential
handshake both report the same kill as **`exec_error`** — which the table would
otherwise route to "the daemon watched the dispatch die", a true sentence
pointing at the wrong repair.

What every one of those paths shares is the message, composed in one place by
`(*SpawnPlan).timeoutReason`
([`pkg/extension/dispatchtimeout.go`](https://github.com/kottera/kottera/blob/main/pkg/extension/dispatchtimeout.go)).
So **a hint that does not read the message cannot know whether it is talking
about a timeout**, whatever code it read.

That is the failure this section exists to prevent. On 2026-09-09 a Work Order
was killed at its 3h ceiling — the payload said so to the half-second — and the
hint authored minutes later told the next attempt it had *"**STOPPED** rather
than … decided it had failed"* and that "a plain resume cleared" the same shape
before. Those are different diagnoses with different repairs: a dispatch that
stopped wants resuming, and one killed on a clock wants its remaining work to
fit the clock. The evidence was on the very event the hint was attached to.
"No ending record, no branch pushed, nothing on `main`" reads as the signature
of a dispatch that stopped, and is **equally** the signature of one that was
killed; the payload disambiguates for free.
