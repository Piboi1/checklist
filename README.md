# Checklist widget

A macOS desktop widget for today's tasks.

- **Check off** a task by tapping its circle on the widget.
- **Add tasks** with the **+** on the widget. It opens a small window with the cursor already in the box. Press return to add one task, or use the list icon to paste a whole list (one task per line; `-`, `1.` and `[ ]` prefixes are stripped).
- **Empty / all done:** the widget turns into a sunset clock with a 24-hour day bar.
- Tasks finished on an earlier day are removed automatically; unfinished ones carry over.

Native widgets can't contain a text field, which is why adding goes through the small app window.

## Setup (macOS 14+, Xcode 15+)

```sh
brew install xcodegen
```

1. In `project.yml`, set `DEVELOPMENT_TEAM` (your team ID; a free Apple ID works) and change `BUNDLE_PREFIX` to something unique, e.g. `com.yourname`.
2. `xcodegen` creates `Checklist.xcodeproj`. Open it.
3. Pick the **Checklist** scheme and press Run once. This installs the app and registers the widget.
4. Right-click the desktop, choose **Edit Widgets**, search **Checklist**, and add the small, medium or large size.

If the widget stays empty after you add tasks, check that both targets have the same App Group under Signing & Capabilities.

## Layout

- `Shared/` task storage (JSON in the App Group container) and the check-off intent, compiled into both targets
- `Widget/` the widget (task list and empty state)
- `App/` the quick-add window
