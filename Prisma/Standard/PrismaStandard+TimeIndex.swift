//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
//  Created by Matthew Jörke on 2/28/24.
//

import Foundation

func getTimeIndex(startDate: Date, endDate: Date) -> [String: Any?] {
    let calendar = Calendar.current
    let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate)
    let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate)
    let isRange = startDate != endDate
    
    var timeIndex: [String: Any?] = ["range": isRange]
    
    addTimeIndexComponents(&timeIndex, dateComponents: startComponents, suffix: ".start")
    
    if isRange { // only write end date and range if it is a range type
        addTimeIndexComponents(&timeIndex, dateComponents: endComponents, suffix: ".end")
        addTimeIndexRangeComponents(&timeIndex, startComponents: startComponents, endComponents: endComponents)
    }
    
    return timeIndex
}

func addTimeIndexComponents(_ timeIndex: inout [String: Any?], dateComponents: DateComponents, suffix: String) {
    timeIndex["year" + suffix] = dateComponents.year
    timeIndex["month" + suffix] = dateComponents.month
    timeIndex["day" + suffix] = dateComponents.day
    timeIndex["hour" + suffix] = dateComponents.hour
    timeIndex["minute" + suffix] = dateComponents.minute
    timeIndex["second" + suffix] = dateComponents.second
    timeIndex["dayMinute" + suffix] = calculateDayMinute(hour: dateComponents.hour, minute: dateComponents.minute)
    timeIndex["15minBucket" + suffix] = calculate15MinBucket(hour: dateComponents.hour, minute: dateComponents.minute)
}

func addTimeIndexRangeComponents(_ timeIndex: inout [String: Any?], startComponents: DateComponents, endComponents: DateComponents) {
    timeIndex["year.range"] = getRange(
        start: startComponents.year,
        end: endComponents.year,
        maxValue: Int.max
    )
    timeIndex["month.range"] = getRange(
        start: startComponents.month,
        end: endComponents.month,
        maxValue: 12,
        startValue: 1 // months are 1-indexed
    )
    timeIndex["day.range"] = getRange(
        start: startComponents.day,
        end: endComponents.day,
        maxValue: daysInMonth(month: startComponents.month, year: startComponents.year),
        startValue: 1 // days are 1-indexed
    )
    timeIndex["hour.range"] = getRange(
        start: startComponents.hour,
        end: endComponents.hour,
        maxValue: 23
    )
    timeIndex["minute.range"] = getRange(
        start: startComponents.minute,
        end: endComponents.minute,
        maxValue: 59
    )
    timeIndex["dayMinute.range"] = getRange(
        start: calculateDayMinute(hour: startComponents.hour, minute: startComponents.minute),
        end: calculateDayMinute(hour: endComponents.hour, minute: endComponents.minute),
        maxValue: 1439
    )
    timeIndex["15minBucket.range"] = getRange(
        start: calculate15MinBucket(hour: startComponents.hour, minute: startComponents.minute),
        end: calculate15MinBucket(hour: endComponents.hour, minute: endComponents.minute),
        maxValue: 95
    )
    timeIndex["second.range"] = getRange(
        start: startComponents.second,
        end: endComponents.second,
        maxValue: 59
    )
}

// swiftlint:disable discouraged_optional_collection
func getRange(start: Int?, end: Int?, maxValue: Int?, startValue: Int = 0) -> [Int]? {
    guard let startInt = start, let endInt = end, let maxValueInt = maxValue else {
        return nil
    }
    
    if startInt <= endInt {
        return Array(startInt...endInt)
    } else {
        return Array(startInt...maxValueInt) + Array(startValue...endInt)
    }
}

func daysInMonth(month: Int?, year: Int?) -> Int? {
    let dateComponents = DateComponents(year: year, month: month)
    let calendar = Calendar.current
    guard let date = calendar.date(from: dateComponents),
          let range = calendar.range(of: .day, in: .month, for: date) else {
            return nil // Provide a default value in case of nil
        }
    return range.count
}

func calculateDayMinute(hour: Int?, minute: Int?) -> Int? {
    guard let hour = hour, let minute = minute else {
        return nil
    }
    return hour * 60 + minute
}

func calculate15MinBucket(hour: Int?, minute: Int?) -> Int? {
    guard let hour = hour, let minute = minute else {
        return nil
    }
    return hour * 4 + minute / 15
}