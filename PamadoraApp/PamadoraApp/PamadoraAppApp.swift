//
//  PomodoroAppApp.swift
//  PomodoroApp
//
//  Created by MIERAIDIHAIMU MIERAISAN on 30/04/2025.
//

import SwiftUI
import Cocoa
import UserNotifications

@main
struct PomodoroAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Use a MenuBarExtra for a modern macOS menu bar app structure
        // Or keep Settings scene if you plan to have a settings window
        Settings {
            EmptyView() // Keep this if you are not using a WindowGroup
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, PomodoroTimerDelegate { // Added PomodoroTimerDelegate
    var statusItem: NSStatusItem!
    var timer: Timer?
    
    // Define base durations
    let workSessionDuration: Int = 25 * 60
    let shortBreakDuration: Int = 5 * 60
    // To be used later if you implement long breaks:
    // let longBreakDuration: Int = 15 * 60
    // var sessionsBeforeLongBreak: Int = 4
    
    // PomodoroTimerDelegate properties
    var timeRemaining: Int
    var isWorkSession: Bool = true
    var isPaused: Bool = true
    var completedSessions: Int = 0
    
    // Conformance to new delegate properties
    var initialWorkDuration: Int { return workSessionDuration }
    var initialBreakDuration: Int { return shortBreakDuration }
    
    var popover: NSPopover!
    var contentView: ContentView! // Hold a reference to update delegate if needed
    
    override init() {
        self.timeRemaining = workSessionDuration // Initialize with work duration
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load any saved timer state from previous session
        loadSavedTimerState()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted { print("Notification permission granted") }
            else if let error = error { print("Notification permission error: \(error.localizedDescription)") }
        }
        
        contentView = ContentView(appDelegate: self)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.title = formattedTime(timeRemaining)
            button.action = #selector(togglePopover)
        }
        
        updateMenuBarTitle() // Ensure UI reflects loaded state
        
        // Register for sleep and wake notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc func systemWillSleep(_ notification: Notification) {
        print("System is going to sleep.")
        // Action: Pause the timer if it's running and save its state.
        if !isPaused {
            print("Timer was running, pausing due to sleep.")
            pauseTimer() // This already sets isPaused = true
            // Optionally, set a flag to know it was sleep-induced
            UserDefaults.standard.set(true, forKey: "PomodoroPausedDueToSleep")
        }
        // Save current state regardless of whether it was running,
        // as the user might expect the current time to be preserved.
        saveCurrentTimerState()
    }
    
    @objc func systemDidWake(_ notification: Notification) {
        print("System woke up.")
        // Action: Decide what to do.
        // You could automatically resume, ask the user, or simply update the UI.
        
        // Reload state to ensure consistency, though it should be okay if saved on sleep.
        // loadSavedTimerState() // Typically not needed if state managed internally correctly
        
        if UserDefaults.standard.bool(forKey: "PomodoroPausedDueToSleep") {
            print("Timer was paused due to sleep. User can manually resume or reset from the UI.")
            UserDefaults.standard.removeObject(forKey: "PomodoroPausedDueToSleep") // Clean up flag
        }
        
        // Ensure the menu bar title and ViewModel are up-to-date
        updateMenuBarTitle()
        // The ViewModel will pick up changes on its next update cycle.
        // If immediate ContentView update is needed, you'd trigger something in contentView.viewModel.
    }
    
    // This delegate method is called when the application is about to terminate
    // This includes system shutdown, user quitting the app, etc.
    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate (e.g., system shutdown, user quit).")
        // Action: Stop the timer and save any final state.
        if timer?.isValid ?? false { // Check if timer is actually running
            pauseTimer() // Ensure timer is stopped and isPaused is set correctly
        }
        saveCurrentTimerState() // Save final progress
        
        print("Final timer state saved. Pomodoro app is shutting down gracefully.")
        
        // If you wanted to "reset the status" on shutdown (e.g., clear session count):
        // self.completedSessions = 0
        // UserDefaults.standard.set(self.completedSessions, forKey: "PomodoroCompletedSessions")
        // print("Completed sessions reset for next launch.")
    }
    
    // MARK: - State Persistence (UserDefaults)
    
    func saveCurrentTimerState() {
        UserDefaults.standard.set(timeRemaining, forKey: "PomodoroTimeRemaining")
        UserDefaults.standard.set(isWorkSession, forKey: "PomodoroIsWorkSession")
        UserDefaults.standard.set(completedSessions, forKey: "PomodoroCompletedSessions")
        UserDefaults.standard.set(isPaused, forKey: "PomodoroIsPaused") // Important to save paused state
        UserDefaults.standard.synchronize() // Ensure it's written immediately, though often not strictly needed
        print("Timer state saved: \(timeRemaining)s, work: \(isWorkSession), sessions: \(completedSessions), paused: \(isPaused)")
    }
    
    func loadSavedTimerState() {
        if UserDefaults.standard.object(forKey: "PomodoroTimeRemaining") != nil { // Check if key exists
            timeRemaining = UserDefaults.standard.integer(forKey: "PomodoroTimeRemaining")
            isWorkSession = UserDefaults.standard.bool(forKey: "PomodoroIsWorkSession")
            completedSessions = UserDefaults.standard.integer(forKey: "PomodoroCompletedSessions")
            isPaused = UserDefaults.standard.bool(forKey: "PomodoroIsPaused")
            
            // If the loaded state indicates the timer should have ended, or for a clean start:
            if timeRemaining <= 0 && !isPaused { // If timer was 0 and supposedly running
                isPaused = true // Default to paused if we need to reset
                // Reset to the beginning of the session type it was in
                timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration
            } else if timeRemaining <= 0 && isPaused { // If timer was 0 and paused, keep as is or reset
                timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration
            }
            // If isPaused was true, it respects that. If false, the timer will start if startTimer() is called.
            // The default behavior of the app should handle starting if !isPaused and timeRemaining > 0.
            
        } else {
            // No saved state, initialize to default work session, paused.
            print("No saved state found, initializing to default.")
            timeRemaining = workSessionDuration
            isWorkSession = true
            completedSessions = 0
            isPaused = true // Start paused by default on first launch
        }
        print("Timer state loaded: \(timeRemaining)s, work: \(isWorkSession), sessions: \(completedSessions), paused: \(isPaused)")
    }
    
    func startTimer() {
        isPaused = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        updateMenuBarTitle() // Good to update immediately
    }
    
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        updateMenuBarTitle() // Good to update immediately
    }
    
    func resetTimer() {
        isPaused = true
        timer?.invalidate()
        timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration
        updateMenuBarTitle()
    }
    
    func switchMode() {
        let wasPausedBeforeSwitch = isPaused // Preserve user's paused state preference
        
        isPaused = true // Pause before switching
        timer?.invalidate()
        
        isWorkSession.toggle()
        timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration
        
        if !wasPausedBeforeSwitch { // If timer was running before switch, resume it
            startTimer()
        } else {
            updateMenuBarTitle() // If it remains paused, just update title
        }
    }
    
    @objc func updateTimer() { /* ... ensure this handles timeRemaining hitting 0 ... */
        guard !isPaused else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateMenuBarTitle()
        } else {
            // Timer reached zero
            let sessionJustEndedWasWork = isWorkSession
            
            NSSound(named: "Glass")?.play()
            sendNotification(isWorkSession: sessionJustEndedWasWork)
            
            if sessionJustEndedWasWork {
                completedSessions += 1
            }
            
            // Switch mode and automatically start next session
            isWorkSession.toggle()
            timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration
            // isPaused remains false (or rather, startTimer will set it to false)
            startTimer() // this will update the menu bar title as well
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover.contentViewController?.view.window?.makeKey() // Ensure popover can receive events
            }
        }
    }
    
    
    
    func sendNotification(isWorkSession justEndedWork: Bool) {
        let content = UNMutableNotificationContent()
        if justEndedWork {
            content.title = "Work Session Complete!"
            content.body = "Time for a refreshing break."
        } else {
            content.title = "Break Over!"
            content.body = "Ready to focus on the next work session?"
        }
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Immediate
        UNUserNotificationCenter.current().add(request)
    }
    
    func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func updateMenuBarTitle() {
        if let button = statusItem.button {
            button.title = formattedTime(timeRemaining)
            
            if isWorkSession {
                button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Work Session")
            } else {
                button.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Break Session")
            }
            statusItem.length = NSStatusItem.variableLength
        }
    }
    
    func resetCompletedSessions() {
        completedSessions = 0
    }
}
