# Contributing

## Welcome, Trooper!

Thanks for helping with the **Troop Tracker mobile app**. These guidelines match the main
[Troop Tracker repository](https://github.com/obsidianslicers/trooper-tracker/blob/main/CONTRIBUTING.md).

## 1. Open an issue first

- **Bugs:** label **`bug`**, with steps to reproduce, the device and OS version, and screenshots.
- **Features:** label **`enhancement`** or **`feature`**, and explain the benefit before writing code.
- **Refactors:** label **`refactor`**.

## 2. Make the change

1. Fork and clone, then create a branch named `<type>-<issue-number>` (e.g. `fix-42`).
2. Set up your environment: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
3. Write the code, following [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#coding-conventions).
4. **Write the tests.** Every change needs them; see [docs/TESTING.md](docs/TESTING.md). Pull
   requests without tests for their changes won't be merged.
5. Check it:
   ```bash
   flutter test
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   ```

## 3. Commit

Angular-style commits with the issue number:

```
<type>(<scope>): <subject> (#<issue-number>)
```

For example: `fix(notifications): keep the badge after clearing the inbox (#42)`.

## 4. Open a pull request

Open it against **`main`** and write `Closes #<issue-number>` in the description. CI checks
formatting, analysis, the unit and widget tests, and the e2e tests on an
Android emulator; all must pass before review.
