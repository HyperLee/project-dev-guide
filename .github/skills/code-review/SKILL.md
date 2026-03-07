---
name: code-review
description: "Perform a comprehensive code review as a senior software engineer. Use when: (1) Reviewing code changes, pull requests, or diffs, (2) Analyzing code snippets for security, performance, or quality issues, (3) Providing constructive feedback on code architecture and design, (4) Identifying potential bugs, vulnerabilities, or anti-patterns, or (5) Any request involving code review, code audit, code feedback, or code quality assessment."
---

# Code Review

Conduct a detailed code review of a given code snippet. Identify potential issues, suggest improvements, and highlight best practices.

## Review Areas

Analyze the selected code for:

1. **Security Issues**
   - Input validation and sanitization
   - Authentication and authorization
   - Data exposure risks
   - Injection vulnerabilities

2. **Performance & Efficiency**
   - Algorithm complexity
   - Memory usage patterns
   - Database query optimization
   - Unnecessary computations

3. **Code Quality**
   - Readability and maintainability
   - Proper naming conventions
   - Function/class size and responsibility
   - Code duplication

4. **Architecture & Design**
   - Design pattern usage
   - Separation of concerns
   - Dependency management
   - Error handling strategy

5. **Testing & Documentation**
   - Test coverage and quality
   - Documentation completeness
   - Comment clarity and necessity

## Output Format

Provide feedback as:

**🔴 Critical Issues** - Must fix before merge
**🟡 Suggestions** - Improvements to consider
**✅ Good Practices** - What's done well

## Core Principles for Feedback

When providing feedback, always remember:

- **Be specific** about what needs to change, not vague
- **Explain why**, not just what - help the author understand the reasoning
- **Suggest alternatives** when possible - offer multiple solutions or approaches

## Detailed Feedback Structure

For each issue:

- Specific line references
- Clear explanation of the problem
- Suggested solution with code example (consider multiple alternatives)
- Rationale for the change - explain the "why" behind your suggestion

Focus on: ${input:focus:Any specific areas to emphasize in the review?}
