//
//  ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetControl.swift
//  1. `SafeParentsWidget`&#x20; 1. `SafeParentsWidget`&#x20; SafeParentsWidget
//
//  Created by MacMini4 on 2026/3/12.
//

import AppIntents
import SwiftUI
import WidgetKit

struct ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetControl: ControlWidget {
    static let kind: String = "com.zzoutuo.safeparents.1. `SafeParentsWidget`&#x20; 1. `SafeParentsWidget`&#x20; SafeParentsWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

extension ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true // Check if the timer is running
            return ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Name Configuration"

    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
}

struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    @Parameter(title: "Timer Name")
    var name: String

    @Parameter(title: "Timer is running")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        // Start the timer…
        return .result()
    }
}
