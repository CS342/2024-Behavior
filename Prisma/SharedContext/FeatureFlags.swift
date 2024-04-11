//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A collection of feature flags for the Prisma application.
enum FeatureFlags {
    private static var cache: [String: Bool] = [:]

    private static func flag(forKey key: String, commandLinePrefix: String) -> Bool {
        if let cachedValue = cache[key] {
            return cachedValue
        }
        
        let value: Bool
        if CommandLine.arguments.contains(commandLinePrefix) {
            value = true
            print("Saving key \(key): \(value)")
            UserDefaults.standard.set(value, forKey: key)
        } else {
            value = UserDefaults.standard.bool(forKey: key)
            
        }
        
        cache[key] = value
        return value
    }

    static var skipOnboarding: Bool {
        flag(forKey: "skipOnboarding", commandLinePrefix: "--skipOnboarding")
    }
    
    /// Always show the onboarding when the application is launched. Makes it easy to modify and test the onboarding flow without the need to manually remove the application or reset the simulator.
    static var showOnboarding: Bool {
        flag(forKey: "showOnboarding", commandLinePrefix: "--showOnboarding")
    }
    
    /// Disables the Firebase interactions, including the login/sign-up step and the Firebase Firestore upload.
    static var disableFirebase: Bool {
        flag(forKey: "disableFirebase", commandLinePrefix: "--disableFirebase")
    }
    
    #if targetEnvironment(simulator)
    /// Defines if the application should connect to the local firebase emulator. Always set to true when using the iOS simulator.
    static let useFirebaseEmulator = true
    #else
    /// Defines if the application should connect to the local firebase emulator. Always set to true when using the iOS simulator.
    static var useFirebaseEmulator: Bool {
        flag(forKey: "useFirebaseEmulator", commandLinePrefix: "--useFirebaseEmulator")
    }
    #endif
    
    /// Adds a test task to the schedule at the current time
    static var testSchedule: Bool {
        flag(forKey: "testSchedule", commandLinePrefix: "--testSchedule")
    }
    
    /// Strips down the application to just onboarding + healthkit data upload, for research study purposes.
    static var healthKitUploadOnly: Bool {
        flag(forKey: "healthKitUploadOnly", commandLinePrefix: "--healthKitUploadOnly")
    }
}
