//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project.
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Firebase
import FirebaseCore
import FirebaseMessaging
import Spezi
import SpeziFirebaseConfiguration
import SwiftUI


/// This file implements functions necessary for push notifications to be implemented within the Prisma application.
/// Includes methods for monitoring token refresh, using methods from the PrismaStandard to upload them to a user's
/// collection in Firebase.
class PrismaPushNotifications: NSObject, Module, NotificationHandler, NotificationTokenHandler, MessagingDelegate,
                               UNUserNotificationCenterDelegate, EnvironmentAccessible {
    @Application(\.registerRemoteNotifications) var registerRemoteNotifications
    @StandardActor var standard: PrismaStandard
    @Dependency private var configureFirebaseApp: ConfigureFirebaseApp
    
    override init() {}
    
    
    func configure() {
        Messaging.messaging().delegate = self
    }
    
    func handleNotificationsAllowed() async throws {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        // prompt the user to allow notifications, both remote and local
        if try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {
            // don't register for remote notifications in the study
            if !FeatureFlags.healthKitUploadOnly {
                try await registerRemoteNotifications()
            }
        }
    }
    
    func receiveUpdatedDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func handleNotificationAction(_ response: UNNotificationResponse) async {
        // right now the default action is when a user taps on the notification. functionality can be expanded in the future.
        if let sentTimestamp = response.notification.request.content.userInfo["sent_timestamp"] as? String {
            let openedTimestamp = Date().toISOFormat(timezone: TimeZone(abbreviation: "UTC"))
            await standard.addNotificationOpenedTimestamp(timeSent: sentTimestamp, timeOpened: openedTimestamp)
        } else {
            print("Sent timestamp is not a string or is nil")
        }
    }
    
    func receiveIncomingNotification(_ notification: UNNotification) async -> UNNotificationPresentationOptions? {
        let receivedTimestamp = Date().toISOFormat(timezone: TimeZone(abbreviation: "UTC"))
        if let sentTimestamp = notification.request.content.userInfo["sent_timestamp"] as? String {
            await standard.addNotificationReceivedTimestamp(timeSent: sentTimestamp, timeReceived: receivedTimestamp)
        } else {
            print("Sent timestamp is not a string or is nil")
        }
        
        return [.badge, .banner, .list, .sound]
    }
    
    func receiveRemoteNotification(_ remoteNotification: [AnyHashable: Any]) async -> BackgroundFetchResult {
        let receivedTimestamp = Date().toISOFormat(timezone: TimeZone(abbreviation: "UTC"))
        if let sentTimestamp = remoteNotification["sent_timestamp"] as? String {
            await standard.addNotificationReceivedTimestamp(timeSent: sentTimestamp, timeReceived: receivedTimestamp)
        } else {
            print("Sent timestamp is not a string or is nil")
        }
        return .noData
    }

    /// This function listens for token refreshes and updates the specific user token to Firestore.
    /// This callback is fired at each app startup and whenever a new token is generated.
    ///
    /// Token refreshes may occur when:
    /// - the app is restored on a new device
    /// - the user uninstalls/reinstall the app
    /// - the user clears app data.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Update the token in Firestore:
        // The standard is an actor, which protects against data races and conforms to
        // immutable data practice. Therefore we get into new asynchronous context and execute
        Task {
            await standard.storeToken(token: fcmToken)
        }
    }
    
    /// Sends a local notification to reopen the app to resume HK Data upload.
    func sendHealthKitUploadPausedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Health Data Upload Paused"
        content.body = "Please open the app to continue the upload of your health data."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
