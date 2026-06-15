# System Working Agreement

We are building an interview assignment: a real-time notification service
with ASP.NET Core, SignalR, EF Core, simplified JWT auth, unread persistence,
notification history with pagination, old notification cleanup, and a simple
HTML demo client.

The important evaluation criterion is not only working software, but also
Solution Driven Development:
- the human owns goals, architecture, tradeoffs, and verification;
- AI agents implement code and tests;
- all prompts, generated docs, decisions, and corrections must be saved.

Rules:
1. Do not silently expand scope.
2. Prefer vertical slices.
3. Generate tests together with implementation.
4. If a bug appears, propose a corrective prompt and fix through code changes.
5. Record architecture decisions in docs/AI_DECISIONS.md.
6. Keep known non-blocking issues in docs/KNOWN_ISSUES.md.
7. Use clear commits after each working slice.
8. Do not ask for hidden chain-of-thought. Provide concise assumptions,
   alternatives, decisions, and verification steps instead.
