# Pomodoro Timer for Mac Menu Bar

A simple Pomodoro timer that lives in your Mac menu bar, helping you manage your study and work sessions with timed intervals.

## Features

- Menu bar timer display showing remaining time
- Work sessions (default: 25 minutes)
- Break sessions (default: 5 minutes)
- Notifications when sessions end
- Simple popup interface to control the timer
- Start, pause, reset functionality
- Switch between work and break modes

## Building the App

You can build this app using Swift directly from the command line:

```bash
cd /Users/mier/Documents/Projects/PamodoraMacMenubar
swiftc -o PomodoroTimer PomodoroTimer.swift -framework Cocoa -framework SwiftUI
```

Or you can open the folder in Xcode and build it there.

## Running the App

After building, you can run the app by double-clicking on the compiled executable or by running:

```bash
./PomodoroTimer
```

## Customization

You can customize the work and break durations by modifying the values in the `PomodoroTimer.swift` file:

- Work session duration: Change `timeRemaining: Int = 25 * 60` to your preferred duration in minutes * 60
- Break session duration: Change the value in the `resetTimer()` function from `5 * 60` to your preferred duration in minutes * 60

## Requirements

- macOS 11.0 or later
- Swift 5.0 or later
