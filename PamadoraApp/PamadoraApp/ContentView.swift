//
//  ContentView.swift
//  PomodoroApp
//
//  Created by MIERAIDIHAIMU MIERAISAN on 30/04/2025.
//

import SwiftUI

//
//  ContentView.swift
import SwiftUI

// Protocol for AppDelegate functionality needed by ContentView (ensure this matches the definition above)
// protocol PomodoroTimerDelegate { ... } // Keep if not in a separate file

// Make AppDelegate conform to the protocol (ensure this matches the definition above)
// extension AppDelegate: PomodoroTimerDelegate {} // Keep if not in a separate file

struct CircularProgressView: View {
    let progress: Double
    let baseColor: Color
    let lineWidth: CGFloat = 10 // Thickness of the progress ring

    var body: some View {
        ZStack {
            Circle() // Background track for the progress ring
                .stroke(baseColor.opacity(0.3), lineWidth: lineWidth)
            
            Circle() // Foreground progress ring
                .trim(from: 0, to: CGFloat(progress))
                .stroke(baseColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Start from the top
                .animation(.linear, value: progress)
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel
    
    init(appDelegate: PomodoroTimerDelegate) {
        self.viewModel = ViewModel(appDelegate: appDelegate)
    }
    
    private var currentThemeColor: Color {
        viewModel.isWorkSession ? .indigo : .teal
    }
    
    private var currentThemeBackgroundColor: Color {
        viewModel.isWorkSession ? .indigo.opacity(0.1) : .teal.opacity(0.1)
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 8)

            HStack {
                Image(systemName: viewModel.isWorkSession ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundColor(currentThemeColor)
                Text(viewModel.isWorkSession ? "Work Session" : "Break Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(currentThemeColor)
            }
            
            ZStack {
                CircularProgressView(
                    progress: viewModel.currentProgress,
                    baseColor: currentThemeColor
                )
                .frame(width: 150, height: 150) // Adjust size as needed
                
                Text(viewModel.timeString)
                    .font(.system(size: 40, weight: .bold, design: .monospaced)) // Slightly smaller font
                    .foregroundColor(currentThemeColor)
            }
            .padding(.vertical, 5) // Add some padding around the timer/progress view
            
            HStack(spacing: 8) {
                ForEach(0..<min(viewModel.completedSessions, 8), id: \.self) { _ in
                    Circle()
                        .fill(currentThemeColor.opacity(0.8)) // Use theme color
                        .frame(width: 10, height: 10) // Slightly smaller dots
                }
                ForEach(0..<max(0, min(8, 8 - viewModel.completedSessions)), id: \.self) { _ in // Ensure non-negative range
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 10, height: 10)
                }
                
                if viewModel.completedSessions > 8 {
                    Text("+\(viewModel.completedSessions - 8)")
                        .font(.caption)
                        .foregroundColor(currentThemeColor.opacity(0.8))
                }
            }
            .padding(.vertical, 5)
            
            HStack(spacing: 15) { // Adjusted spacing
                Button(action: {
                    viewModel.startPauseTimer()
                }) {
                    HStack {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        Text(viewModel.isPaused ? "Start" : "Pause")
                    }
                    .frame(minWidth: 90, idealWidth: 100, maxHeight: 36) // Use minWidth
                    .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent) // More modern button style
                .tint(viewModel.isPaused ? currentThemeColor : .orange) // Dynamic tint
                
                Button(action: {
                    viewModel.resetTimer()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .frame(minWidth: 90, idealWidth: 100, maxHeight: 36)
                    .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.9))
            }
            
            Button(action: {
                viewModel.switchMode()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(viewModel.isWorkSession ? "Switch to Break" : "Switch to Work")
                }
                .frame(minWidth: 200, idealWidth: 215, maxHeight: 36) // Adjusted to sum of two buttons + spacing
                .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isWorkSession ? Color.green.opacity(0.8) : Color.blue.opacity(0.8)) // Different colors for switch
            
            Divider()
                .padding(.vertical, 5)
            
            HStack {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.secondary)
                    Text("Mier's Pomodoro")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.resetCompletedSessions()
                }) {
                    HStack {
                        Image(systemName: "gobackward.minus")
                        Text("Reset Count")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain) // Less prominent style
                .tint(currentThemeColor)


                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
// Text("Quit") // Icon only for less clutter, or keep text if preferred
                    }
                    .font(.caption)
                    .padding(5)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .help("Quit Application") // Tooltip
            }
        }
        .padding()
        .background(currentThemeBackgroundColor) // Dynamic background for the content
        .frame(width: 320, height: 360) // Adjusted height slightly for new layout
        .background(Color(NSColor.windowBackgroundColor)) // Ensure window background for areas outside content
        .cornerRadius(12)
    }
}

// Mock delegate for SwiftUI Previews
class MockPomodoroDelegate: PomodoroTimerDelegate {
    var timeRemaining: Int = 25 * 60
    var isWorkSession: Bool = true
    var isPaused: Bool = true
    var completedSessions: Int = 3
    
    // Added for protocol conformance
    var initialWorkDuration: Int = 25 * 60
    var initialBreakDuration: Int = 5 * 60
    
    func startTimer() { isPaused = false }
    func pauseTimer() { isPaused = true }
    func resetTimer() { timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration }
    func switchMode() {
        isWorkSession.toggle()
        timeRemaining = isWorkSession ? initialWorkDuration : initialBreakDuration
    }
    func resetCompletedSessions() { completedSessions = 0 }
}

#Preview {
    ContentView(appDelegate: MockPomodoroDelegate())
}
