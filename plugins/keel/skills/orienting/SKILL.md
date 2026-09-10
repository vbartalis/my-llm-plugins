---
name: orienting
description: Use at the start of any change in this monorepo, before designing or coding - establishes which apps and boundaries the change touches and what class of change it is
---

# Orienting

**Announce:** "I'm using the orienting skill to map what this change touches."

The first stage. Before you know *what* to build you must know *where* it
lands. In a single app that question answers itself. In this repo it does not,
and getting it wrong is the failure mode that has cost the most: a change
designed inside one app's worldview that silently breaks the shape another
app depends on.

Orienting is cheap. Ninety seconds for a local change. Do not skip it because
you think you already know the answer — writing it down is what makes the
answer checkable by someone else.

<HARD-GATE>
Do not invoke `keel:brainstorming`, propose a design, or touch code until your
human partner has agreed with the surface. The surface is what everything
downstream is designed against; a wrong surface makes every later stage wrong.
</HARD-GATE>

## The Process

### Step 1: Create the workspace

```
scripts/keel workspace new <kebab-slug>
```

Creates `docs/keel/features/YYYY-MM-DD-<slug>/`. Slug describes the change,
not the ticket. If a workspace for this work already exists, use it.

For a spike you may skip the workspace — see classification below.

### Step 2: Read the law

Read `docs/keel/constitution.md` if it exists. It outranks everything you are
about to write. If a constraint in it bears on this change, quote it into
`surface.md` rather than paraphrasing.

### Step 3: Inventory what exists

Find the ground truth. Do not rely on memory of this repo.

- Identify the apps/packages in the monorepo and their languages.
- For each one you suspect is involved, find the actual entry point and the
  actual place data enters or leaves it.
- Follow the data. If the change concerns a piece of information, trace where
  it is produced, where it is stored, and every place it is read.

Prefer dispatching a search agent for the sweep if the repo is large — you
want the conclusion, not every file in your context.

### Step 4: Classify

Pick exactly one class and say it out loud so your partner can override it:

- **spike** — a feasibility question whose output is an answer, not code you
  keep. Say what you will try in two sentences, get a nod, find out as cheaply
  as correctness allows, report a recommendation. Anything built is labelled
  throwaway. **Exits the pipeline here.** No design.md, no plan.md.
- **local** — one app, and the flow you are changing already exists there to
  read. Understanding what kind of app it is does not make a change local; the
  flow must be present. Light ceremony downstream.
- **cross-app** — two or more apps change, but no shape or protocol between
  them changes. Full design and plan.
- **boundary** — a shape, schema, protocol, event, or public interface between
  apps changes, or a new one is introduced. Highest ceremony. Every consumer
  must be named before design begins.

When torn between two classes, take the heavier one. The cost of over-classing
is a few paragraphs. The cost of under-classing is a rebuild.

### Step 5: Write surface.md

Use the template in `references/surface-template.md`. Fill every section. A
section with nothing in it says "none" — it never gets deleted, because an
empty section is itself information.

One field is mechanical and must be exact:

- **`## Watch`** — a fenced block listing every file this change will touch: the
  declarations you found in Step 3, the files that define the shapes and
  endpoints you named, the migration files. One path per line, repo-relative.

The Watch block is the mechanical projection of the Contracts section. Contracts
names shapes in prose; Watch names the files a command can actually resolve. If
a shape you named has no file in Watch, you have not finished tracing it.

It is also the path set the pre-build participant points scope against. Until a
build produces a diff, this block is the only statement of what the change will
touch — a reviewer registered for paths you left out is never dispatched.

### Step 5b: Advisors

```
scripts/keel participants --at orient
```

Invoke any advisor listed. They shape the surface; they do not approve it.

### Step 6: Gate

Dispatch any gate reviewers:

```
scripts/keel participants --at surface-gate
```

Their verdicts are advisory — present them with the surface. Agents inform
gates; your human partner decides them. See
`../using-keel/references/participants.md`.

Present the surface: the class, the apps, and the boundaries crossed, in a few
lines of chat, with the path to the file. Ask whether the surface is right.

Wait for agreement. Then:

**Next stage:** invoke `keel:brainstorming`. If the class is `spike`, do not —
run the spike and report.

## Getting The Surface Right

**Consumers, not callers.** The question is not "what calls this code" but
"what depends on this shape being what it is". A UI that renders a field
depends on it. A report that aggregates it depends on it. A test fixture that
hardcodes it depends on it.

**Look for the second copy.** When a shape crosses into another app, that app
very often has its own declaration of it — a type, an interface, a struct, a
serialiser. Find it. Two declarations of one shape is the drift you are trying
to stop, and orienting is where it becomes visible.

**Name the owner.** For each shape or boundary crossed, say which app is
authoritative for it. If two apps both believe they own it, that is a finding
and it goes in `surface.md` under Risks — you have found the actual bug.

**Language boundaries are boundaries.** A shape that exists in TypeScript and
in Go is crossing a boundary even if both live in this repo and never speak
over a network.

## Red Flags

| Thought | Reality |
|---------|---------|
| "It's only the frontend" | The frontend consumes shapes. That is a boundary. Class it. |
| "I'll find the consumers as I go" | Consumers found during coding are found by breaking them. |
| "Both apps already use this type" | Then say which one owns it. If neither, you found a bug. |
| "Classification is bureaucracy" | It selects the ceremony for four later stages. It is the cheapest decision here. |
| "I'll write surface.md after designing" | Then you designed against an unverified surface. |
