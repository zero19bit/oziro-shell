# Cross-component tests

Unit tests currently live next to their owning Rust and frontend modules.

This directory is reserved for integration tests that require more than one Oziro component, such as:
- native bridge contract tests
- compositor adapter tests
- session lifecycle tests
- multi-monitor behavior tests

Do not put environment-dependent tests in the default unit-test path unless they can be skipped safely when the required service is unavailable.
