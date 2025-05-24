//
//  ViewModel.swift
//  PamadoraApp
//
//  Created by MIERAIDIHAIMU MIERAISAN on 24/05/2025.
//

import SwiftUI // For @Published and ObservableObject
import Combine // For Timer if not already imported

protocol PomodoroTimerDelegate: AnyObject { // Added AnyObject for weak delegate references if needed elsewhere
    var timeRemaining: Int { get set }
    var isWorkSession: Bool { get set }
    var isPaused: Bool { get set }
    var completedSessions: Int { get set }
    
    // New properties for initial durations
    var initialWorkDuration: Int { get }
    var initialBreakDuration: Int { get }
    
    func startTimer()
    func pauseTimer()
    func resetTimer()
    func switchMode()
    func resetCompletedSessions()
}

class ViewModel: ObservableObject {
    private var appDelegate: PomodoroTimerDelegate
    private var cancellables = Set<AnyCancellable>() // For more robust timer handling if refactored later
    
    @Published var timeString: String = "25:00"
    @Published var isWorkSession: Bool = true
    @Published var isPaused: Bool = true
    @Published var completedSessions: Int = 0
    
    // New properties for progress bar
    @Published var currentProgress: Double = 0.0
    @Published var currentSessionInitialDuration: Int // Needs to be initialized

    init(appDelegate: PomodoroTimerDelegate) {
        self.appDelegate = appDelegate
        // Initialize currentSessionInitialDuration correctly
        self.currentSessionInitialDuration = appDelegate.isWorkSession ? appDelegate.initialWorkDuration : appDelegate.initialBreakDuration
        
        self.updateFromAppDelegate() // Initial update
        
        // Consider using Combine's Timer publisher for more SwiftUI-idiomatic updates
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateFromAppDelegate()
        }
    }
    
    func updateFromAppDelegate() {
        let newTimeRemaining = appDelegate.timeRemaining
        let newIsWorkSession = appDelegate.isWorkSession
        let newIsPaused = appDelegate.isPaused
        let newCompletedSessions = appDelegate.completedSessions

        // Update initial duration if mode changed
        self.currentSessionInitialDuration = newIsWorkSession ? appDelegate.initialWorkDuration : appDelegate.initialBreakDuration
        
        let minutes = newTimeRemaining / 60
        let seconds = newTimeRemaining % 60
        self.timeString = String(format: "%02d:%02d", minutes, seconds)
        
        self.isWorkSession = newIsWorkSession
        self.isPaused = newIsPaused
        self.completedSessions = newCompletedSessions
        
        if self.currentSessionInitialDuration > 0 {
            self.currentProgress = 1.0 - (Double(newTimeRemaining) / Double(self.currentSessionInitialDuration))
        } else {
            self.currentProgress = 0.0 // Avoid division by zero; handle as complete or error
        }
    }
    
    func startPauseTimer() {
        if appDelegate.isPaused {
            appDelegate.startTimer()
        } else {
            appDelegate.pauseTimer()
        }
        updateFromAppDelegate() // Ensure UI updates immediately
    }
    
    func resetTimer() {
        // appDelegate.pauseTimer() // Pause is good practice before reset
        appDelegate.resetTimer() // This will also update timeRemaining in AppDelegate
        // currentSessionInitialDuration will be updated in updateFromAppDelegate
        updateFromAppDelegate()
    }
    
    func switchMode() {
        // appDelegate.pauseTimer() // Pause before switching
        appDelegate.switchMode()
        // currentSessionInitialDuration will be updated in updateFromAppDelegate
        updateFromAppDelegate()
    }
    
    func resetCompletedSessions() {
        appDelegate.resetCompletedSessions()
        updateFromAppDelegate()
    }
}
