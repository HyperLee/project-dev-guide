# Workflow Phases

Detailed execution instructions for each phase. Load this file when executing the Fleet Commander workflow.

## Table of Contents

- [Phase 0: Team Assignment](#phase-0-team-assignment)
- [Phase 1: Analysis & Planning](#phase-1-analysis--planning)
- [Phase 2: Implementation](#phase-2-implementation)
- [Phase 2.5: Testing Gate](#phase-25-testing-gate)
- [Phase 3: Security Gate](#phase-3-security-gate)
- [Phase 3.5: Architecture Gate](#phase-35-architecture-gate)
- [Phase 4: Committee Review](#phase-4-committee-review)
- [Phase 5: Final Output & Git Ops](#phase-5-final-output--git-ops)

---

## Phase 0: Team Assignment

**Active Agent:** Fleet Commander

Randomly assign one unique model from the Model Pool to each agent. Output:

```
🤖 Team Lineup (Randomly Assigned):
  • PM:   [Model]
  • Dev:  [Model]
  • Test: [Model]
  • Sec:  [Model]
  • Arch: [Model]
```

Every model must be used exactly once (one agent gets no assignment or two agents share if only 4 models and 5 agents — assign 4 unique models, pick any remaining agent to share with the closest-fit model).

---

## Phase 1: Analysis & Planning

**Active Agents:** PM_Agent, Test_Agent

### PM_Agent Tasks
1. Requirement breakdown — decompose `[PROJECT_REQUIREMENTS]` into discrete features
2. Define scope & constraints — technology boundaries, non-functional requirements
3. Identify dependencies and risks

### Test_Agent Tasks
1. Define Acceptance Criteria per feature
2. Design unit test scenarios (xUnit + Moq)
3. Design integration test scenarios (WebApplicationFactory)

### PM_Agent Final Output
- Execution plan with TDD-first approach
- Ordered task list for Dev_Agent

---

## Phase 2: Implementation

**Active Agent:** Dev_Agent

### Technical Requirements
- .NET 10+ Minimal API
- Dependency Injection / async / nullable enabled
- Global Exception Handling middleware
- Logging abstraction (Serilog style)
- Clean Architecture / Vertical Slice pattern

### Output
Full initial implementation covering all features from Phase 1 execution plan.

Include:
- Project structure
- All source files
- Unit test stubs (following Test_Agent's scenarios)
- Integration test stubs

---

## Phase 2.5: Testing Gate

**Active Agents:** Test_Agent → Dev_Agent (loop)

### Loop (MAX 3 attempts)

**Step 1 — Test_Agent: Execute Tests**
- Run xUnit + Moq (unit tests)
- Run WebApplicationFactory (integration tests)
- Report results

**Step 2 — If FAIL: Test_Agent Analysis**
- List failed test cases
- Root Cause Analysis for each failure

**Step 3 — Dev_Agent: Apply Fix**
- Choose strategy: `HOTFIX` / `REFACTOR` / `REDESIGN`
- Output **DIFF ONLY** (changed snippets)
- Verify anti-regression: new fix must not break passing tests

**Step 4 — Re-run Tests**
- Test_Agent re-executes all tests
- If PASS → exit loop, continue to Phase 3
- If FAIL → increment loop counter, repeat from Step 1

### Exit Conditions
- ✅ **PASS** → Proceed to Phase 3
- ❌ **FAIL after 3 attempts** → **ESCALATE**

### Escalation Report Format
```
## 🚨 Testing Escalation Report

### Failed Tests Summary
- [Test Name]: [Failure Description]

### Root Causes
1. [Root Cause Analysis]

### Suggested Redesign Direction
- [Architectural or design changes needed]
```

---

## Phase 3: Security Gate

**Active Agents:** Sec_Agent → Dev_Agent (loop)

### Loop (MAX 3 attempts)

**Step 1 — Sec_Agent: OWASP Top 10 Audit**
- Scan all implementation code
- Check for injection, broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, XSS, insecure deserialization, known vulnerabilities, insufficient logging

**Step 2 — If Vulnerability Found: Sec_Agent Report**
```
⚠️ CRITICAL WARNING
- Vulnerability: [Type]
- Location: [File:Line]
- Root Cause: [Description]
- Exploit Scenario: [How it can be exploited]
- Fix Recommendation: [Specific fix]
```

**Step 3 — Dev_Agent: Apply Fix**
- Choose strategy: `HOTFIX` / `REFACTOR` / `REDESIGN`
- Output **DIFF ONLY**
- Verify anti-regression

**Step 4 — Re-audit**
- Sec_Agent re-audits all code
- If SECURE → exit loop, continue to Phase 3.5
- If VULNERABLE → increment loop counter, repeat

### Exit Conditions
- ✅ **SECURE** → Proceed to Phase 3.5
- ❌ **FAIL after 3 attempts** → **ESCALATE**

### Escalation Report Format
```
## 🚨 Security Escalation Report

### Risk Summary
- [Vulnerability]: [Severity Level]

### Impact Analysis
- [What can be exploited and consequences]

### Required Redesign Scope
- [What needs fundamental rework]
```

---

## Phase 3.5: Architecture Gate

**Active Agents:** Arch_Agent → Dev_Agent (loop)

### Loop (MAX 3 attempts)

**Step 1 — Arch_Agent: Evaluate**
- SOLID principles compliance
- Layer separation (Clean Architecture boundaries)
- Testability of design
- Cohesion and coupling analysis

**Step 2 — If Issue Found: Arch_Agent Report**
```
🏗️ ARCH WARNING
- Issue: [Description]
- Principle Violated: [SOLID principle or pattern]
- Root Cause: [Why this happened]
- Refactor Suggestion: [Specific improvement]
```

**Step 3 — Dev_Agent: Apply Fix**
- Choose strategy: `HOTFIX` / `REFACTOR` / `REDESIGN`
- Output **DIFF ONLY** + strategy tag
- Verify anti-regression

**Step 4 — Re-review**
- Arch_Agent re-evaluates all code
- If APPROVED → exit loop, continue to Phase 4
- If ISSUE → increment loop counter, repeat

### Exit Conditions
- ✅ **APPROVED** → Proceed to Phase 4
- ❌ **FAIL after 3 attempts** → **ESCALATE**

### Escalation Report Format
```
## 🚨 Architecture Escalation Report

### Design Flaw Summary
- [Flaw]: [Impact on maintainability]

### Refactor / Redesign Proposal
- [Specific architectural changes needed]
```

---

## Phase 4: Committee Review

**Active Agents:** All

Final gate — every agent votes Pass/Fail on their domain.

| Role | Status | Review Focus |
|------|--------|-------------|
| PM_Agent | Pass / Fail | Scope completeness, requirement coverage |
| Test_Agent | Pass / Fail | Test stability, coverage adequacy |
| Sec_Agent | Pass / Fail | Security posture, remaining risks |
| Arch_Agent | Pass / Fail | Design quality, maintainability |

### Decision Rules
- ✅ **ALL PASS** → Proceed to Phase 5
- ❌ **ANY FAIL** → **STOP** — do NOT proceed to Phase 5. Output the failing agent's concerns and required fixes.

---

## Phase 5: Final Output & Git Ops

**Precondition:** ALL agents passed in Phase 4.

### 1. Full Final Code

Output the **COMPLETE consolidated code** for all files (not diffs).

### 2. Git Commands

```bash
git checkout -b feat/[feature-name]
git add .
git commit -m "feat: [descriptive commit message]"
git push origin feat/[feature-name]
```

### 3. PR Description Template

```markdown
## Summary
- [List of features implemented]

## Testing
- ✅ xUnit unit tests: Passed
- ✅ Integration tests (WebApplicationFactory): Passed

## Security
- ✅ OWASP Top 10 audit: Passed
- [Any specific security measures taken]

## Architecture
- ✅ Clean Architecture review: Approved
- ✅ SOLID principles: Verified
- [Key architectural decisions]

## Type
- [ ] Feature
- [ ] Bug Fix
- [ ] Refactor
```
