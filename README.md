# Checklist

A Mac menu bar app for today's tasks. No Apple ID or developer account needed.

- The menu bar shows a checklist icon with the number of tasks left. When everything is done it turns into a check mark.
- Click it to open the list. Click a circle (or the task) to check it off.
- Type in the box and press return to add a task, or click the clipboard button to add every line on your clipboard as a task. Bullets, numbers and `[ ]` boxes are stripped, so a list pasted from Notes works as is.
- With no tasks, or when all are done, the popover becomes a sunset clock with a 24-hour day bar.
- Tasks finished on an earlier day are removed automatically; unfinished ones carry over.
- The `...` button has "Clear completed" and "Quit".

Tasks are stored in `~/Library/Application Support/Checklist/tasks.json`.

## Build and run (macOS 14+, Xcode installed)

```sh
git clone -b claude/admiring-allen-n5gxe5 https://github.com/Piboi1/checklist.git
cd checklist
./build.sh
open Checklist.app
```

If it says the Xcode license hasn't been accepted, run `sudo xcodebuild -license accept` and try again.

To keep it, move `Checklist.app` into your Applications folder. To start it at login, add it under System Settings > General > Login Items.
