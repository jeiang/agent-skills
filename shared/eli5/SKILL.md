---
name: eli5
description: Explain something at the right level for the person asking — code, a system, an error, a concept — grounded in the actual thing rather than the general pattern. Use when the user asks to explain something simply, in plain terms, like they're five, or says they don't understand how something works. Do NOT use for ordinary answers that happen to include an explanation.
argument-hint: "[eli5|colleague|expert]"
---

# ELI5

Explaining is not simplifying. It is finding where the reader is standing and
building a path from there to the thing they asked about.

## Establish the footing first

Before choosing an altitude, work out what the reader already knows. Their
question usually says: the vocabulary they use, what they got right, and where
their model breaks. A Kubernetes operator asking about the borrow checker is
not a beginner, they are an expert in a different place.

Levels, when the invocation names one:

- `eli5` — assume no domain vocabulary. Everything is built from ordinary
  experience. Still never inaccurate.
- `colleague` (default) — assume general competence, no familiarity with this
  particular system or concept.
- `expert` — assume the domain, explain only what is specific, surprising, or
  non-obvious here. Skip the foundations entirely.

When no level is given, infer it from the question and say which one you
picked in one clause, so the reader can redirect you.

## Ground it in the real thing

Read the actual code, config, or output before explaining it. Explain what
*this* implementation does, citing file and line — not what the pattern
generally does. A generic account of a repository pattern does not help
someone who is confused by this repository's version of it.

If the explanation requires a fact you have not verified, verify it or say
you are inferring. Confident wrongness is the main way explanation fails.

## Build it

1. Lead with the answer in one or two sentences. The reader should be able to
   stop there and have gained something.
2. Then expand, concrete before general: a specific example first, the rule it
   illustrates second. Never the reverse.
3. Give the real name of everything alongside the plain-language version, so
   the reader can search for it afterward.
4. Explain the hard part. Whatever you are most tempted to wave past is
   usually what they were actually asking about.
5. Stop when the question is answered. Do not append a tour of adjacent
   concepts they did not ask for.

## Analogies

An analogy has to be load-bearing: it must let the reader predict something
they could not predict before. If it only makes the topic feel familiar, cut
it — the feeling of understanding without the substance is worse than an
honest "this one is genuinely unlike anything else."

State where every analogy breaks down. Readers extend analogies past their
limits, and an undisclosed limit becomes their next bug.

## Do not

- Talk down. No "basically", "just", "simply", or "all it really does is" in
  front of something that took the reader an hour to hit.
- Fake precision with invented numbers, percentages, or history.
- Explain the easy 90% and skip the hard 10%.
- Restate the code in prose line by line. That is transcription, not
  explanation.

Stop when the explanation answers the question. Include a next action only
when it helps the reader use the answer; do not add a compulsory closing recap.
