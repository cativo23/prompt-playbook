# Prompt Playbook

> Volume 0x01 :: Issue 0x01 :: Philes 0x00-0x07 :: a field guide for agents
> Facts below carry a source link. Lines marked "Advice" are rules of thumb, not facts.
> Version-gated and plan-dependent defaults were checked 2026-11-14 and may change.

**Free your context.** The agent does what you ask, not what you mean. Vague prompts tend to become big contexts, and big contexts cost usage on every turn. This zine is the fix.

Index:
- 0x00 Why prompts cost tokens
- 0x01 The formula (WHAT / LIMIT / DONE / HOW)
- 0x02 Before / after
- 0x03 Prompting agents
- 0x04 Context hygiene
- 0x05 Asking for the output you want
- 0x06 Pocket prompts
- 0x07 Settings that guard you

---

## 0x00 :: THE PHYSICS — Every turn re-reads everything

The model keeps no memory between requests, so each turn the agent re-sends the full context: system prompt, project context, every prior message and tool result, plus your new message. Caching only avoids reprocessing the unchanged prefix, which is re-read at a cheaper cached rate. The context is still carried and billed on every turn. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

Cost scales with context size, and tool use multiplies it: every tool call triggers another request that carries the whole history. Even with caching, a one-line question in a session open all day still draws usage for the whole conversation. [costs](https://code.claude.com/docs/en/costs)

### How the cache works

- Matching is exact-prefix. A change anywhere in the prefix recomputes everything after it; there is no per-file or per-segment caching. Rarely-changing content (system prompt, tool definitions, project context) comes first and the conversation last, so appending is cheap and altering early content is expensive. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- Cached prefixes expire after inactivity, and each cache hit resets the timer. The first message after a break longer than the cache lifetime reprocesses the full context (slower and costlier). [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- The API offers a 5-minute and a 1-hour TTL. The 1-hour one charges a higher rate for cache writes, so it helps when you leave a session idle and come back, and costs more on short bursts that never idle past five minutes. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- Default TTL in Claude Code depends on how you pay. The main conversation gets 1 hour only on a Claude subscription within included plan usage; with usage credits, an API key or a cloud provider it gets 5 minutes. Subagents, workflows, compaction and session titles default to 5 minutes, except a small set of server-controlled helper requests on a subscription. TTL controls need v2.1.242+. Defaults may change, so treat this as true as of 2026-11-14. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Where it leaks

Idle sessions can still consume usage:

| Leak | Why it hurts | Source |
|---|---|---|
| session-scoped scheduled tasks | fire on their interval while idle and send the full context each time | [costs](https://code.claude.com/docs/en/costs) |
| messages from other sessions | delivered as a new turn when the session is idle | [costs](https://code.claude.com/docs/en/costs) |
| active-goal check-ins | can start idle turns (at most three per goal between your prompts) | [costs](https://code.claude.com/docs/en/costs) |
| session recap and idle compaction | can use tokens while you are away; idle compaction applies to a conversation on the one-hour TTL | [costs](https://code.claude.com/docs/en/costs), [prompt-caching](https://code.claude.com/docs/en/prompt-caching) |

<!-- UNSOURCED: the original page's meter bars (ctx 50K = 1x, 200K = 4x, 500K = 10x), the "400K tokens costs as much as reading a novel" line, and the leaks "sessions open for days", "agents that never finish" and '"continue" with no end'. The claims support "cost scales with context size" but give no ratios or numbers. Dropped; a human can decide whether to keep an illustrative meter labeled as an estimate. -->

---

## 0x01 :: THE FORMULA — Four pieces, one line each

A prompt does not need to be long. Advice: make it answer four questions.

| Piece | Answers | Support |
|---|---|---|
| WHAT | goal, plus the file or area and the symptom | Name the file or area, describe the symptom, and say what "fixed" looks like up front. This gives the agent information it cannot get from the repo and usually saves a round of corrections. [best-practices](https://code.claude.com/docs/en/best-practices) |
| LIMIT | scope, in either direction | The agent tends to read a request conservatively and build the smallest thing that satisfies it. If you want edge cases, empty and error states or the natural follow-on, say so (the docs use the phrase "be ambitious"). [best-practices](https://code.claude.com/docs/en/best-practices) Advice: you own scope, so state it both ways. |
| DONE | a check that returns pass or fail | Without one, "looks done" is all the agent has to go on, and in practice you become the test suite. Examples of checks: tests, build exit code, linter, fixture diff, screenshot vs mockup. [best-practices](https://code.claude.com/docs/en/best-practices) |
| HOW | preferences, plan mode, reasons | If you care which of two reasonable approaches the agent picks, state it, because it can't be read from the code. [best-practices](https://code.claude.com/docs/en/best-practices) Explain the reason behind an instruction, not just the rule; context or motivation helps the model deliver more targeted results. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) |

> **RULE** Advice: end every work prompt with the check that proves it is finished ("Done when ___").

### Sanity checks

- **Colleague test.** If a colleague with minimal context would be confused by your prompt, the model will be too. Use numbered lists or bullets when the order or completeness of steps matters. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- **Ask for evidence.** Ask for the command run and its output, or a screenshot, not just "all tests pass". For a session you weren't watching, it is the only evidence you have. [best-practices](https://code.claude.com/docs/en/best-practices)
- **Plan before act.** Plan mode lets the agent read files and propose a plan with no edits until you approve. Enter it with `claude --permission-mode plan` or Shift+Tab mid-session. Use it for changes you want to review before they touch disk. [common-workflows](https://code.claude.com/docs/en/common-workflows)
- **Course-correct early.** Watch the first minute and press Esc the moment the agent drifts. Esc stops mid-action and keeps everything up to that point; `/rewind` (or Esc twice on an empty prompt) opens a menu to roll the code, the conversation, or both back to an earlier prompt. [best-practices](https://code.claude.com/docs/en/best-practices)
- **Exploring is different.** Vague prompts are fine for exploration (e.g. "what would you improve in this file?"). You'll correct a bit more as you go. Spend specificity where you already know what you want. [best-practices](https://code.claude.com/docs/en/best-practices)

---

## 0x02 :: BEFORE / AFTER — Same intent, fewer correction rounds

**PATCH 01 :: no symptom, no location, no check**

```diff
- fix the login bug
+ users report login fails after the session times out. look at token refresh
+ in src/auth/, write a failing test that reproduces it, then fix it
```
Added: symptom, location, a reproducing failing test, then the fix. [best-practices](https://code.claude.com/docs/en/best-practices)

**PATCH 02 :: no pattern, no constraint**

```diff
- add a calendar widget
+ follow the pattern in ExistingWidget.php and build a calendar widget that lets
+ you pick a month and page between years. no new libraries
```
Added: an existing pattern to copy and a constraint. (The docs' own example uses a different file name.) [best-practices](https://code.claude.com/docs/en/best-practices)

**PATCH 03 :: describing the thing instead of handing it over**

Reference a file with `@path`, paste screenshots of designs or errors, and pipe command output into the prompt. The docs example is `cat error.log | claude -p "what's going on here"`. [best-practices](https://code.claude.com/docs/en/best-practices)

**PATCH 04 :: advice when you wanted action**

```diff
- can you suggest some changes to the retry logic?
+ change the retry logic so it backs off after the third failure
```
Phrasing like "can you suggest some changes" may get suggestions instead of edits, so say "change this" when you want the change made. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

<!-- UNSOURCED: the original PATCH 01 ("run test --filter=Cart, 3 are red ..."), PATCH 02 (RefundService) and PATCH 03 ("yes go ahead, continue with push and PRs") were not covered by the claims. Replaced with sourced pairs. If you want an equivalent of the old PATCH 03 ("continue" with no scope), there is no claim for it. -->

---

## 0x03 :: AGENTS — Start small, delegate on purpose

### Subagent or team?

Start with a subagent, not an agent team. Subagents work inside one session and return a result to the caller. Teammates are separate, fully independent sessions that message each other directly. Subagents cost less because results are summarized back into the main context; teams cost more because each teammate is its own Claude instance. Use subagents for focused workers that report back, and teams when workers need to share findings and challenge each other. [agent-teams](https://code.claude.com/docs/en/agent-teams)

### What it costs

- Teams cost significantly more than a single session, and usage scales with the number of active teammates and how long each runs. Anthropic's cost guide says agent teams use approximately 7x more tokens than standard sessions when teammates run in plan mode. [costs](https://code.claude.com/docs/en/costs) For routine tasks a single session is more cost-effective. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Anthropic's multi-agent research system measured agents using about 4x more tokens than chat, and multi-agent systems about 15x more. Token usage by itself explained 80% of the variance on BrowseComp. Reserve multi-agent setups for tasks whose value is high enough to pay for the increased performance. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)
- Subagent requests still draw on your usage. [costs](https://code.claude.com/docs/en/costs)

### Subagents save context

Delegate verbose operations (running tests, fetching docs, processing logs) so the noisy output stays in the subagent's context and only a summary returns. Many subagents returning detailed results can still consume significant main-conversation context, and each subagent spends its own tokens. [sub-agents](https://code.claude.com/docs/en/sub-agents) Advice: ask for concise summaries.

### Writing the delegation prompt

- Every delegated worker needs an objective, an output format, guidance on tools and sources, and clear task boundaries. Without detailed task descriptions, Anthropic found agents duplicate work, leave gaps, or fail to find necessary information. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)
- A teammate loads the same project context as a regular session (CLAUDE.md, MCP servers, skills) plus the spawn prompt, but the lead's conversation history does not carry over. [agent-teams](https://code.claude.com/docs/en/agent-teams) Everything in the spawn prompt adds to its context from the start. [costs](https://code.claude.com/docs/en/costs) Advice: include the task-specific details it needs (scope, files, constraints, expected output) and little else.
- Size tasks as self-contained units with a clear deliverable, such as a function, a test file or a review. Too small and coordination overhead exceeds the benefit; too large and teammates work too long without check-ins, increasing the risk of wasted effort. The docs suggest 5-6 tasks per teammate. Give each teammate a distinct set of files, because two teammates editing the same file leads to overwrites. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Effort should scale with the task. In Anthropic's research system: simple fact-finding needs 1 agent with 3-10 tool calls, direct comparisons 2-4 subagents with 10-15 calls each, and complex research more than 10 subagents. These are that system's guidance, not a Claude Code rule. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

### Keep teams small and supervised

- Start with 3-5 teammates for most workflows. Token costs scale linearly with team size, while coordination overhead grows and returns diminish, so three focused teammates often outperform five scattered ones. Scale up only when the work benefits from teammates working simultaneously. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Teams start best with research and review tasks that have clear boundaries and don't require writing code, such as reviewing a PR, researching a library or investigating a bug. Monitor and steer instead of leaving a team unattended, which increases the risk of wasted effort. If the lead starts implementing instead of waiting, tell it to wait for teammates to finish. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Shut teammates down when their work is done; each active teammate keeps consuming tokens until it exits or the session ends. Ask the lead to shut one down by name. The teammate can approve or reject with an explanation and finishes its current request or tool call first, so shutdown can be slow. The team config is removed when the session ends, but the task list directory stays on disk. [costs](https://code.claude.com/docs/en/costs), [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Agent teams are experimental and disabled by default (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enables them). Once enabled, a subagent that Claude names launches as a teammate, so a team can form even when you didn't ask for one. Setting the variable to `0` makes named subagents launch as plain subagents again. A higher-precedence settings source or managed settings can still enable it. [agent-teams](https://code.claude.com/docs/en/agent-teams)

### Pick a smaller model for delegated work

Anthropic's cost guidance says to use Sonnet for teammates and to specify `model: haiku` for simple subagent tasks. Subagents that inherit your session model follow it, so switching the main session to Opus also applies to every inheriting subagent. You can name the model in the spawn prompt (for example "Use Sonnet for each teammate"). [costs](https://code.claude.com/docs/en/costs), [agent-teams](https://code.claude.com/docs/en/agent-teams)

### When NOT to use agents or teams

For sequential tasks, same-file edits and work with many dependencies, a single session or subagents are more effective. Frequent back-and-forth, iterative refinement, phases that share significant context, quick targeted changes and latency-sensitive work belong in the main conversation. [agent-teams](https://code.claude.com/docs/en/agent-teams), [sub-agents](https://code.claude.com/docs/en/sub-agents) Anthropic's research post also notes that domains where all agents must share the same context, or with many dependencies between agents, are a poor fit for multi-agent systems today, and that most coding tasks involve fewer truly parallelizable tasks than research. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

### Pre-flight checklist (advice)

1. Does the deliverable fit in one sentence? If you need "and also...", it is probably two jobs.
2. Did you say what to read and what the output should look like?
3. Is there a finish line the agent can check?
4. Do you even need an agent? A single session is the default for routine work.

<!-- UNSOURCED: the original story of one agent fixing 13 findings for a thousand turns, the "split by deliverable" example (blocker / 4 majors / 8 minors), "under ~10 steps, just do it in the main session", and "Agents report back within ~100 turns". Rewritten around the sourced task-sizing and cost guidance. The turn-limit idea has no claim. -->

---

## 0x04 :: CONTEXT HYGIENE — Clear between tasks, compact on purpose

| Command | What it does | Cost |
|---|---|---|
| `/clear` | fresh context for an unrelated task | costs nothing itself [costs](https://code.claude.com/docs/en/costs) |
| `/compact` | summarizes the history | sends a separate summarization request that includes the history being summarized [prompt-caching](https://code.claude.com/docs/en/prompt-caching) |
| `/rewind` | truncates back to an earlier turn | back to a prefix that is already cached, rather than building a new one [prompt-caching](https://code.claude.com/docs/en/prompt-caching) |

- **Clear between unrelated tasks.** Stale context costs tokens on every later message. Run `/rename` first so you can find the session and `/resume` it later. [costs](https://code.claude.com/docs/en/costs)
- **Compact has a price tag.** While the cache is warm the request mostly reads the cached prefix (cheap). After an idle gap beyond the TTL it reprocesses the whole history uncached, so compacting an old resumed session is the most expensive case. The turn after compaction rebuilds the cache for only the much shorter history. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- **Compact at natural breaks** (between tasks) rather than letting auto-compaction trigger mid-task. If you went down a path you want to abandon entirely, `/rewind` to an earlier turn instead. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- **Steer what survives.** Run `/compact` with instructions (e.g. `/compact focus on the auth bug fix`), or add a "Compact instructions" section to the project's CLAUDE.md. [context-window](https://code.claude.com/docs/en/context-window.md), [costs](https://code.claude.com/docs/en/costs)
- **Know what is re-injected.** After compaction the project-root CLAUDE.md, unscoped rules and auto memory are re-injected from disk. Rules with `paths:` frontmatter and nested CLAUDE.md files are summarized away with the conversation and only reload on demand. Put must-survive rules in the root CLAUDE.md (or drop the `paths:` frontmatter). [context-window](https://code.claude.com/docs/en/context-window.md)

### Don't break the cache mid-task

Avoid mid-task changes that invalidate the cache: switching models (each model has its own cache), turning fast mode on or off, connecting or deliberately removing an MCP server (when tool search does not defer its tools), denying a whole tool when tool search is off, accumulating many images, and upgrading the tool. With tool search active (the default on supported models), the MCP and deny-rule cases do not disturb the cache. Pick model and effort at the start of a session. Editing CLAUDE.md mid-session does not invalidate the cache, but it also does not apply until `/clear`, `/compact` or a restart. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Keep context small at the source

- Delegate verbose operations (tests, docs fetching, log processing) to subagents so only a summary returns.
- Use hooks to preprocess noisy output (e.g. trim test output to the last 100 lines).
- Prefer CLI tools (`gh`, `aws`, `gcloud`) over MCP servers where available.
- Disable unused MCP servers via `/mcp`.
- Aim to keep CLAUDE.md under 200 lines and move workflow-specific instructions into on-demand skills.

All five: [costs](https://code.claude.com/docs/en/costs). The 200-line figure is the docs' "aim to" guidance.

### Inspect before you guess

- `/context` shows a live breakdown of context by category with optimization suggestions, including which CLAUDE.md and auto memory files loaded. [context-window](https://code.claude.com/docs/en/context-window.md)
- `/usage` shows session token totals. On Pro, Max, Ultra, Team and Enterprise plans it also attributes recent usage to skills, subagents, plugins and MCP servers with recommendations. After the first response it adds a "Prompt cache (main)" line with the cache-hit share, misses, and whether the cache is warm or cold (v2.1.251+); it can name the likely cause of the last miss (v2.1.260+). [costs](https://code.claude.com/docs/en/costs)

<!-- UNSOURCED: the original handoff-file section (HANDOFF.md prompt, "/clear then read HANDOFF.md"), the "clear beats compact" framing, and the rule "hand off when context passes ~300-500K". No claim supports the handoff pattern or those thresholds. Removed rather than invented. A human can restore the handoff prompt as clearly-labeled personal advice. The sourced alternative for carrying work across sessions is the SPEC.md pattern in 0x06. -->

---

## 0x05 :: OUTPUT — Ask for the shape you want

Be specific about the output you want: state the format and constraints explicitly. If you want more than the bare task, ask for it explicitly instead of relying on the model to infer it from a vague prompt. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### Format

- **Say what you want, not what you don't.** Use "Your response should be composed of smoothly flowing prose paragraphs" instead of "Do not use markdown in your response". [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- **Your prompt's style can influence the answer's style.** If formatting still won't steer, try matching the prompt's style to the output you want; removing markdown from your prompt can reduce the volume of markdown in the output. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- **Use XML tags to separate instructions, context and input.** They help Claude parse complex prompts unambiguously, especially when a prompt mixes instructions, context, examples and variable inputs. Wrap each type in its own tag (for example `<instructions>`, `<context>`, `<input>`). [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- **Skip preambles with a direct instruction:** `Respond directly without preamble. Do not start with phrases like "Here is...", "Based on...", etc.` The docs list alternatives (output within XML tags, structured outputs, or tool calling) and say to strip the occasional preamble in post-processing. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### Length (the docs' samples are for Claude Opus 5)

- **Ask for length; don't lower effort to get it.** Effort controls how much the model thinks rather than how much it says. Lowering effort can reduce thinking without reliably shortening the visible response. Official sample: *"Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested."* In a long system prompt, pair it with a short reminder near the end. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- **Calibrate written deliverables separately.** Files written to disk are often longer than on prior models. Sample: *"Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate."* [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- **Shape the end-of-task report.** Sample: *"When you finish, lead with the outcome: your first sentence should answer 'what happened' or 'what did you find,' with supporting detail after it for readers who want it."* Positive examples of the communication style you want tend to be more effective than instructions about what not to do. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)

### Questions and decisions

- **Limit clarifying questions by saying when one is allowed.** Scope-control sample for Opus 5: *"Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it."* [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- **Invite questions on purpose.** If you haven't pinned down what you want, ask Claude to interview you until it could write the spec, and save it to a file. Claude comes back with multiple-choice questions about the parts you haven't pinned down. Then build from the spec in a fresh session so the build begins with clean context and a written definition of done. [best-practices](https://code.claude.com/docs/en/best-practices)
- **Advice without edits.** Claude's latest models follow instructions precisely, so "can you suggest some changes" may get suggestions rather than edits. For a conservative mode the docs show a system-prompt snippet saying not to change files unless clearly instructed, and that when intent is ambiguous the model should default to providing information, doing research and providing recommendations rather than taking action. Ask for action explicitly when you want edits. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- **Be careful limiting review output.** The Opus 5 guide says that if a review prompt says "only report high-severity issues" or "be conservative", the model might follow that literally and report less. Ask it to report everything and filter in a separate pass. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)

### Machine-readable output (API)

- Structured outputs constrain the response to a JSON schema via `output_config.format` with type `json_schema` (constrained decoding). The docs list "Always valid: No JSON parsing errors" and "Type safe: Guaranteed field types and required fields". Caveats: refusals (`stop_reason` "refusal") and `max_tokens` cut-offs can yield output that doesn't match the schema, and enum values may differ in capitalization, so compare them case-insensitively. For classification, use an enum field with your valid labels (via tools or structured outputs). [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- Unsupported: recursive schemas, numerical constraints (minimum/maximum), string length constraints, and `additionalProperties` other than false (all objects must set it to false). The first request with a new schema has extra latency while the grammar compiles; compiled grammars are cached for 24 hours from last use. [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- If you can't use structured outputs, try prompting alone first: newer models can reliably match complex schemas when told to, especially if implemented with retries. Prefilling the assistant turn is no longer supported on Claude 4.6 and later models (requests return a 400 error), so format-forcing by prefill needs a different approach. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

<!-- UNSOURCED: the original page's "max 3 options, one line each", "recommend one", "yes/no at the end" and "if it's routine, decide and tell me in one line" shapes. No claim supports them as such; only the sourced "check in only when readings differ materially / make routine judgment calls yourself" sample covers part of it. Keep as personal advice only if a human labels it that way. -->

---

## 0x06 :: POCKET PROMPTS — Copy, fill, send

Replace what is in `<angle brackets>`. Nothing else changes.

**0x06.1 :: SCOPED TASK** (Advice: the WHAT / LIMIT / DONE shape from 0x01)

```
Goal: <one sentence, with the file or area and the symptom>
Only touch: <file or folder>
Done when: <a check that returns pass or fail: test / build / linter>
Show me: the command you ran and its output.
```
Why: name the area and symptom, say what fixed looks like, and ask for evidence. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.2 :: VERIFICATION LOOP**

```
After the change, run <the auth tests> and keep going until they pass.
```
Works for any task with no setup. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.3 :: SELF-CHECK** (append to anything)

```
Before you finish, verify your answer against <test criteria>.
```
The docs say this catches errors reliably, especially for coding and math. Caveat: Claude Opus 5 verifies its own work well without instruction, and carried-over verification instructions can cause over-verification there (extra tokens and latency); the docs say to remove them on that model. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**0x06.4 :: PLAN BEFORE ACTING**

```
Goal: <one sentence>
Read the relevant files and propose a plan. Don't edit anything until I approve.
```
Or start in plan mode: `claude --permission-mode plan`. [common-workflows](https://code.claude.com/docs/en/common-workflows)

**0x06.5 :: NO GOLD-PLATING** (prepend to anything)

```
Only make changes that are directly requested. Don't add features, refactors or
"improvements" beyond what was asked. Don't add docstrings, comments or type
annotations to code you didn't change. Don't add error handling, fallbacks or
validation for scenarios that can't happen. Don't create helpers or abstractions
for one-time operations. Don't add extra configurability.
```
Adapted from the docs' sample prompt. The docs note Claude Opus 4.5 and 4.6 tend to overengineer, so this is most useful if you see that behavior. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**0x06.6 :: BE AMBITIOUS** (the opposite direction)

```
Be ambitious: <empty and error states, the save flow wired up, keyboard navigation>.
```
The agent tends to build the smallest thing that satisfies a request, so ask for more explicitly. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.7 :: INTERVIEW, THEN SPEC**

```
Interview me until you could write the spec, then write it to SPEC.md.
```
Then build from SPEC.md in a fresh session. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.8 :: SPAWN PROMPT** (Advice: shape from the docs' delegation guidance in 0x03)

```
Objective: <one deliverable, e.g. review <path> for <concern>>
Scope: only <files>; do not edit <files>.
Tools/sources: <what to use or read>.
Output: <format>, concise summary only.
Model: <Sonnet>.
```
Why: objective, output format, tool guidance and boundaries. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

**0x06.9 :: UNATTENDED RUN**

```
Success looks like: <what must be true>.
When done, <write the results to ... / post ...>. You cannot ask me questions.
```
Unattended or scheduled runs can't ask clarifying questions, so state success and what to do with the results. [common-workflows](https://code.claude.com/docs/en/common-workflows)

**0x06.10 :: LEAD WITH THE OUTCOME**

```
When you finish, lead with the outcome: your first sentence should answer
"what happened" or "what did you find," with supporting detail after it.
```
Official Opus 5 sample. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)

### Stuck?

After two failed corrections on the same issue, run `/clear` and write one new prompt that folds in what you learned, rather than a third correction. The docs say this works better almost every time; a third correction mostly adds to a conversation that already contains two failed attempts for the agent to keep re-reading. [best-practices](https://code.claude.com/docs/en/best-practices)

<!-- UNSOURCED: the original 0x06.2 "DIAGNOSE FIRST" (find cause, wait for confirmation) and 0x06.5 "AGENT BUDGET" (max 2 agents, ~100 turns, warn at ~400K) are not supported by the claims. 0x06.4 reuses the sourced plan-mode idea in place of the former. -->

---

## 0x07 :: SETTINGS — Guards you set once

Checked against Anthropic's docs, 2026-11-14. Version gates are noted; names and defaults may change.

### Auto-compact window

- Set per model with `/autocompact` (e.g. `/autocompact 500k`, saved under `modelSettings`; `/autocompact auto` restores the tuned default; per-model saving needs v2.1.288+).
- For all models, use the `autoCompactWindow` setting (e.g. `200000` in `~/.claude/settings.json`), `--autocompact` for one launch, or the `CLAUDE_CODE_AUTO_COMPACT_WINDOW` environment variable, which takes precedence unless Claude Code ignores the value.
- The command and flag accept 100K to 1M tokens, and the window is capped at the model's context window.
- **Caution:** an unsuffixed env var value is a raw token count (`200` means 200 tokens), while `/autocompact 200` means 200,000. Out-of-range env values trigger a warning and are clamped; a k/M suffix in the env var needs v2.1.304+.

Source: [model-config](https://code.claude.com/docs/en/model-config.md)

On models with a native 1M context window (Fable models, Sonnet 5 and later, Haiku 5.5, Opus 4.7 and later), auto-compaction happens at about 967K tokens by default. [model-config](https://code.claude.com/docs/en/model-config.md) Advice: since every request carries the context, a smaller window keeps each request smaller. That is this guide's reasoning, not a quoted claim.

### Cache TTL

- `promptCacheTtl` (or `CLAUDE_CODE_PROMPT_CACHE_TTL`) for the main conversation and `subagentPromptCacheTtl` (or `CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL`) for everything else, each `"5m"` or `"1h"` (v2.1.242+).
- API-key and cloud-provider users can set `promptCacheTtl` to `"1h"` for a one-hour main-conversation cache.
- `FORCE_PROMPT_CACHING_5M=1` forces 5 minutes for both buckets and is meant for debugging or overriding managed settings.
- `ENABLE_PROMPT_CACHING_1H=1` requests 1 hour for both buckets.

Source: [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Cut idle and background use

- `idleCompaction: false` stops compacting a conversation you left idle (v2.1.290+).
- `crossSessionInbound: "hold"` holds inbound messages from other sessions instead of delivering them.
- `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` turns off idle goal check-ins.
- Prompt suggestions can be turned off.

Source: [costs](https://code.claude.com/docs/en/costs)

### Subagent model

`CLAUDE_CODE_SUBAGENT_MODEL` sets a default model for subagents, but it is third in precedence: the per-invocation `model` parameter wins, then the subagent definition's `model` field, then this variable, then the main conversation's model. To apply one model to every subagent, teammate and workflow agent, set it together with `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.257+); with FORCE, the spawn-prompt and definition models no longer apply. Setting the variable alone does not change the built-in Explore or Plan subagents. For teammates, a model named in the spawn prompt takes precedence over the variable unless FORCE is set. [sub-agents](https://code.claude.com/docs/en/sub-agents), [agent-teams](https://code.claude.com/docs/en/agent-teams)

### Thinking effort

Lower thinking cost for simple tasks with `/effort` (or in `/model`), since thinking tokens bill as output tokens. You can't turn thinking off on Opus 5.5, Sonnet 5.5, Haiku 5.5 or the Fable models. Changing effort mid-session keeps the cache on Fable 5.1 and later, Opus 5.5, Sonnet 5.5 and Haiku 5.5 with an API key or Claude subscription; on most other models (and on Bedrock, Google Cloud's Agent Platform or a Claude apps gateway) it invalidates the cache. [costs](https://code.claude.com/docs/en/costs), [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Inspect

`/usage` and `/context`: see 0x04. [costs](https://code.claude.com/docs/en/costs), [context-window](https://code.claude.com/docs/en/context-window.md)

<!-- UNSOURCED: the original page's "500000" example value with the claim that /autocompact entries under modelSettings "override" autoCompactWindow. Claims say /autocompact saves under modelSettings but do not state the override. Dropped the override statement. Also dropped the original "/usage press d/w for day or week" detail. awaySummaryEnabled was deliberately omitted (not verified). -->

---

```
-[ EOF ]-------------------------------------------------------------
  greetz to everyone who ever ran out of context at 3am.
  there is no spoon. there is only context.
---------------------------------------------------------------------
  prompt-playbook :: v0x01 :: facts checked 2026-11-14
```
