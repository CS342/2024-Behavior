//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension String {
    /// converts a HKSample Type string representation to a lower cased id.
    /// e.g. "HKQuantityTypeIdentifierStepCount" => "stepcount".
    var healthKitDescription: String {
        let description = self
        if description.hasPrefix("HKQuantityTypeIdentifier") {
            // removes the HKQuantityTypeIdentifier prefix.
            return description.dropFirst(24).lowercased()
        }
        return "unknown"
    }
}

extension Date {
    /// converts Date object to local time.
    func localISOFormat() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    /// one Month in the past.
    func oneMonthInThePast() -> Date? {
        Calendar.current.date(byAdding: .month, value: -1, to: self)
    }
}
