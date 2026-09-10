# Tracing The Data

The technique behind Step 3. Use it when the change concerns a piece of
information rather than a piece of behaviour — which, in this repo, is most of
the time.

## The question

Not "where is this code called from" but **"where does this information live,
and who believes something about its shape."**

## The sweep

For a field, entity, or event, find all five:

1. **Origin** — where the value first comes into existence. User input, an
   external API, a computation, a migration default.
2. **Store** — every place it is persisted. Table columns, cache keys, event
   log payloads, files.
3. **Transport** — every hop where it is serialised. HTTP bodies, RPC
   messages, queue payloads, generated clients.
4. **Declaration** — every place its *shape* is written down. Types,
   interfaces, structs, dataclasses, schemas, validators, ORM models,
   serialisers, GraphQL types, test fixtures, mock factories.
5. **Consumption** — every place a decision is made based on it. Rendering,
   branching, aggregation, authorisation.

Declaration is the one people skip and it is the one that matters. Count the
declarations. If the count is greater than one, the shape has no single owner
and you have found the mechanism by which it will drift.

## Reading the result

| Finding | What it means |
|---------|---------------|
| One declaration, many consumers | Healthy. Change the declaration, consumers follow. |
| Two declarations in two languages | Drift risk. Name an owner in `surface.md`. |
| Two declarations in one language | A bug waiting. Record under Risks. |
| A declaration with no consumer | Dead. Say so; deleting it may be the change. |
| A consumer with no declaration | Something reads this shape untyped. Highest risk of all — it breaks silently. |

## Cost control

This sweep is bounded by the shape, not by the repo. You are looking for one
name and its aliases. Dispatch a search agent with the shape's name and its
plausible spellings across languages (`invoice_id`, `invoiceId`, `InvoiceID`)
and ask for the five categories above as the answer.

Do not read the files yourself unless the agent's answer is ambiguous. You
want the conclusion in your context, not the corpus.
