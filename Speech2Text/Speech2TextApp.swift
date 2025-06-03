//
//  Speech2TextApp.swift
//  Speech2Text
//
//  Created by Jiping Yang on 3/23/25.
//

import SwiftUI

@main
struct Speech2TextApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
}
