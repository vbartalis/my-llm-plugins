---
name: brainstorming
description: Use after orienting and before any planning or code - turns a request into an agreed design through dialogue, producing design.md
---

# Brainstorming

**Announce:** "I'm using the brainstorming skill to turn this into an agreed design."

Second stage. `surface.md` said where the change lands. This stage says **what
it should do and why**, in terms a human can disagree with.

The output is not code and not tasks. It is the argument for the change. If
your partner would reject the finished feature, they should be able to reject
*this file* and save everyone the build.

<HARD-GATE>
Do not write a plan, scaffold anything, or touch implementation code until
your human partner has approved the design. Ceremony scales with the surface
class. This gate does not.
</HARD-GATE>

## Prerequisites

`surface.md` exists and was agreed. If it does not, stop and invoke
`keel:orienting` — you cannot design against an unknown surface.

Read `surface.md` in full, including the Constitution Constraints section. You
design inside those constraints, not around them.

## Ceremony By Class

Read the class from `surface.md`:

| Class | What you do here |
|-------|------------------|
| **local** | Ask the questions that matter, present a short design in chat, get a nod, record it in `design.md` in a few paragraphs. |
| **cross-app** | Full dialogue, full `design.md`, explicit statement of how each app's part fits the others. |
| **boundary** | All of cross-app, plus: the shape being changed written out in full, every consumer named, and the compatibility story stated before anything else. |
| **spike** | You should not be here. Spikes exit at orienting. |

## The Process

### Step 1: Understand the intent

Ask about the *problem*, not the solution. The request describes a solution
your partner already reached for; the design should be judged against the
problem underneath it.

Ask few questions and ask them well. Batch them. The questions worth asking:

- Who has this problem, and what do they do today instead?
- What does success look like from outside the system?
- What is deliberately not being solved?
- Which existing behaviour must not change?

Stop asking when you can state the problem back and your partner agrees.

### Step 2: Find the shape of the answer

Before writing a design, consider more than one approach. Say the alternatives
out loud with one line each on the tradeoff, and recommend one. Your partner
needs the choice visible, not a survey — a recommendation with the discarded
options named is the right amount.

For a **boundary** change, the shape of the data is the design. Write the
shape out. Do not describe it in prose when you can write the actual fields
and types. A design that says "we add invoice metadata" is not a design; one
that lists the fields, their types, their optionality, and who fills each one
is.

### Step 3: Test the design against the surface

Walk the design back through `surface.md`:

- Every app listed as touched — does the design say what changes in it?
- Every consumer named under Contracts — does the design say what that
  consumer sees, and whether it breaks?
- Every risk listed — does the design address it or accept it explicitly?

A design that leaves a listed consumer unmentioned is incomplete, not concise.

### Step 3b: Advisors

```
scripts/keel participants --at design
```

Invoke any advisor listed before you write the design. An advisor is a skill
from outside keel with an opinion about how this kind of thing should be built
— a design system, an accessibility guide, a domain library. It shapes the
design. It has no veto.

### Step 4: Write design.md

Use `references/design-template.md`.

Write it for someone who was not in the conversation. Every question your
partner asked and you answered belongs in the file — the answers are the
design, and losing them is how the same question gets re-litigated in three
weeks.

### Step 5: Gate

Dispatch gate reviewers:

```
scripts/keel participants --at design-gate
```

On `cross-app` and `boundary` designs this resolves to keel's own design
reviewer plus anything the repo has registered. Brief each one with the
artifacts and never with this conversation — see
`../using-keel/references/participants.md`.

Their verdicts are advisory. Present them with your summary; your human partner
decides.

Summarise in chat: the approach, the main tradeoff, findings from the reviewers,
and anything you are unsure about. Give the file path. Ask for approval.

Then:

**Next stage:** invoke `keel:writing-plans`.

## Design Quality

**Argue, don't assert.** "We use a queue here" is an assertion. "We use a
queue here because the webhook must return in under a second and the
downstream write can take ten" is an argument. Arguments survive review;
assertions get overturned by whoever is in the room next.

**Name what you rejected.** The most valuable line in a design document is
often "we considered X and did not do it because Y". It stops the same idea
being re-proposed and re-rejected forever.

**Be specific about behaviour at the edges.** What happens on empty, on
duplicate, on failure, on concurrent, on very large. Most rebuild-triggering
surprises live here.

**Do not design the implementation.** File layout, function names, and task
order belong to the next stage. If you find yourself writing steps, stop —
you are planning, and you have not been approved to plan yet.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The design is obvious, let's just build" | Then it takes three sentences to write down and one nod to approve. |
| "I'll clarify the edge cases during build" | Edge cases discovered during build become rulings made under pressure. |
| "They said what they want, no need to ask why" | They described a solution. Design against the problem. |
| "I'll describe the shape in prose" | Write the fields. Prose about data shapes is how the last one drifted. |
| "This consumer probably doesn't care" | `surface.md` listed it. Say what it sees, even if the answer is 'nothing'. |
| "I'll put alternatives in if they ask" | The rejected option is the part reviewers most need. |
