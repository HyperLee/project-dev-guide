# Performance Review Patterns

Use this reference when performance is a review focus. These patterns apply across most languages and frameworks.

## Algorithm & Data Structure Issues

### O(n^2) When O(n) is Possible
**Pattern**: Nested loops where the inner loop searches for a match in a list.
**Fix**: Use a hash set or hash map for O(1) lookups.
```
# Bad: O(n*m) — checking if items in list A exist in list B
for item in list_a:
    if item in list_b:  # O(m) per check
        ...

# Good: O(n+m) — convert to set first
set_b = set(list_b)  # O(m) once
for item in list_a:
    if item in set_b:  # O(1) per check
        ...
```

### Repeated Work in Loops
**Pattern**: Computing the same value or calling the same function on every iteration.
**Fix**: Hoist invariant computation outside the loop.

### Unbounded Collection Growth
**Pattern**: Lists, maps, or caches that grow without limit.
**Fix**: Add size limits, eviction policies, or time-based expiry.

## Database Performance

### N+1 Query Problem
**Pattern**: Fetching a list, then running one query per item to load related data.
**Fix**: Use JOINs, eager loading, or batch queries.

**How to spot it**: A query inside a loop that iterates over results from another query.

### Missing Indexes
**Pattern**: Queries filtering or sorting on columns without indexes, causing full table scans.
**Fix**: Add appropriate indexes. Be cautious of over-indexing (each index has write-time cost).

### SELECT * When Only a Few Columns Are Needed
**Pattern**: Fetching all columns when only 2-3 are used.
**Fix**: Specify only the needed columns. Reduces network transfer and memory.

### Expensive Operations Inside Transactions
**Pattern**: Long-running computations, external API calls, or file I/O inside a database transaction.
**Fix**: Move non-DB work outside the transaction to reduce lock contention.

## Memory & Resource Patterns

### Unnecessary Copies
**Pattern**: Creating copies of large data structures when a reference or slice would suffice.
**Fix**: Pass by reference, use views/slices, or restructure to avoid copying.

### Resource Leaks
**Pattern**: Opening files, connections, or handles without ensuring cleanup on all code paths (including exceptions).
**Fix**: Use try-with-resources (Java), `with` (Python), `defer` (Go), RAII (Rust/C++).

### Large Object Retained in Long-Lived Scope
**Pattern**: Temporary large objects referenced from a long-lived scope (class field, global, closure), preventing garbage collection.
**Fix**: Set references to null/None when no longer needed, or restructure to limit scope.

## Async & Concurrency Performance

### Sequential Awaits for Independent Operations
**Pattern**: `await a(); await b();` when a and b don't depend on each other.
**Fix**: `await Promise.all([a(), b()])` or equivalent parallel execution.

### Blocking the Event Loop
**Pattern**: CPU-intensive work or synchronous I/O in a single-threaded async context (Node.js, Python asyncio).
**Fix**: Offload to worker threads/processes or use async I/O.

### Excessive Lock Contention
**Pattern**: Using a single lock to protect all shared state, when different parts of the state are accessed independently.
**Fix**: Use fine-grained locks, read-write locks, or lock-free data structures.

## Frontend Performance

### Unnecessary Re-renders (React)
**Pattern**: Components re-rendering when their inputs haven't meaningfully changed.
**Common causes**: New object/array references created on every render, missing `useMemo`/`useCallback` for expensive computations.

### Layout Thrashing
**Pattern**: Reading layout properties (offsetHeight) then immediately writing (style changes) in a loop.
**Fix**: Batch reads together, then batch writes.

### Unoptimized Images/Assets
**Pattern**: Serving full-resolution images for thumbnail views, or loading all assets upfront.
**Fix**: Responsive images, lazy loading, appropriate formats (WebP, AVIF).

### Bundle Size
**Pattern**: Importing entire libraries when only a small part is needed.
**Fix**: Use tree-shakeable imports, dynamic imports for code splitting.

## Caching Patterns

### Missing Cache Invalidation
**Pattern**: Data is cached but never invalidated when the underlying data changes (create, update, delete operations).
**Fix**: Invalidate or update the cache entry whenever the source data is modified. Use consistent cache key patterns and consider write-through or write-behind strategies.

### Caching Null / Error Results
**Pattern**: Cache stores the result of a failed lookup or null response, causing subsequent requests to receive stale "not found" responses even after the data exists.
**Fix**: Only cache successful, non-null results. Alternatively, cache null results with a very short TTL.

### Cache Stampede (Thundering Herd)
**Pattern**: A popular cache key expires and many concurrent requests simultaneously hit the database to regenerate it.
**Fix**: Use lock/mutex on cache miss so only one request regenerates the cache. Alternatively, use background refresh before expiry or probabilistic early expiration.
