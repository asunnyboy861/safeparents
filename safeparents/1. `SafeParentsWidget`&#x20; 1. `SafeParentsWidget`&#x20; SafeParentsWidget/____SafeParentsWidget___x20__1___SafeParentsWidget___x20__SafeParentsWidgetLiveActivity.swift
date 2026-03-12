//
//  ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetLiveActivity.swift
//  1. `SafeParentsWidget`&#x20; 1. `SafeParentsWidget`&#x20; SafeParentsWidget
//
//  Created by MacMini4 on 2026/3/12.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes {
    fileprivate static var preview: ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes {
        ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes(name: "World")
    }
}

extension ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState {
    fileprivate static var smiley: ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState {
        ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState {
         ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.preview) {
   ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetLiveActivity()
} contentStates: {
    ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState.smiley
    ____SafeParentsWidget___x20__1___SafeParentsWidget___x20__SafeParentsWidgetAttributes.ContentState.starEyes
}
