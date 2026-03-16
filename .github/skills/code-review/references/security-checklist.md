# Security Review Checklist

Use this checklist when the code under review handles user input, authentication, data storage, or external communication. Not every item applies to every review — focus on what's relevant.

## Input Handling

- [ ] All user input is validated at the system boundary (type, length, format, range)
- [ ] Input used in SQL queries goes through parameterized queries or prepared statements — never string interpolation
- [ ] Input rendered in HTML is escaped or sanitized to prevent XSS (check both server-rendered and client-side rendering)
- [ ] Input used in shell commands goes through safe APIs (e.g., subprocess with list args) — never `os.system()` or backtick interpolation
- [ ] Input used in file paths is validated against path traversal (`../`, null bytes, symlink attacks)
- [ ] Input used in regex is escaped or validated to prevent ReDoS (catastrophic backtracking)
- [ ] Deserialization of user-controlled data uses safe formats (JSON) not dangerous ones (pickle, eval, YAML `!!python`)
- [ ] Server-side requests do not use user-controlled URLs without allowlist validation (SSRF prevention)

## Authentication & Authorization

- [ ] Authentication checks exist on all endpoints that require them
- [ ] Authorization checks verify the requesting user has permission for the specific resource, not just that they're logged in
- [ ] Object-level authorization checks prevent accessing other users' resources via ID manipulation (IDOR prevention)
- [ ] Session tokens are generated with cryptographically secure random generators
- [ ] Passwords are hashed with a modern algorithm (bcrypt, scrypt, argon2) — not MD5, SHA1, or plain SHA256
- [ ] Failed login attempts are rate-limited to prevent brute force
- [ ] Sensitive operations require re-authentication or step-up auth
- [ ] JWT tokens are validated (signature, expiration, issuer, audience) — not just decoded

## Data Protection

- [ ] Secrets (API keys, passwords, tokens) are not hardcoded in source code
- [ ] Sensitive data is not logged (passwords, tokens, PII, credit card numbers)
- [ ] PII is encrypted at rest if required by compliance
- [ ] Database connections use parameterized queries
- [ ] Error messages don't expose internal implementation details to end users
- [ ] CORS configuration is restrictive (not `*` for authenticated endpoints)
- [ ] HTTP security headers are set (CSP, HSTS, X-Frame-Options, etc.)

## Cryptography

- [ ] Using well-known libraries, not custom crypto implementations
- [ ] Random values for security purposes use cryptographic RNG, not `Math.random()` or `random.random()`
- [ ] Encryption keys are not derived from predictable sources
- [ ] TLS is enforced for all network communication with external services

## Dependency & Supply Chain

- [ ] New dependencies are well-maintained and widely used
- [ ] Dependencies are pinned to specific versions (not floating ranges for security-critical packages)
- [ ] No known vulnerabilities in added dependencies (check advisories)
- [ ] Lock files (package-lock.json, yarn.lock, go.sum) are committed and maintained
- [ ] Build pipeline does not execute untrusted code or download from unverified sources

## API Security

- [ ] Rate limiting is implemented on public-facing endpoints
- [ ] Request body size limits are enforced to prevent DoS
- [ ] API responses don't leak internal identifiers, stack traces, or implementation details
- [ ] API versioning strategy exists for breaking changes
- [ ] Pagination is enforced on list endpoints to prevent unbounded responses

## Logging & Monitoring

- [ ] Sensitive data (PII, tokens, passwords) is never written to logs
- [ ] Security-relevant events are logged (failed auth, permission denied, input validation failures)
- [ ] Log entries include sufficient context for debugging (request ID, user ID, timestamp) without leaking secrets
- [ ] Audit trail exists for destructive or privileged operations
