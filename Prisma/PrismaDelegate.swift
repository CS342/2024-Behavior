//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseCore
import FirebaseMessaging
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirebaseStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziMockWebService
import SpeziOnboarding
import SpeziScheduler
import SwiftUI


class PrismaDelegate: SpeziAppDelegate {
    private let sampleList = [
        // Activity
        HKQuantityType(.stepCount),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.flightsClimbed),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.appleMoveTime),
        HKQuantityType(.appleStandTime),
        
        // Vital Signs
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.walkingHeartRateAverage),
        HKQuantityType(.oxygenSaturation),
        HKQuantityType(.respiratoryRate),
        HKQuantityType(.bodyTemperature),
        
        // Other events
        HKCategoryType(.sleepAnalysis),
        HKWorkoutType.workoutType()
    ]
    
    override var configuration: Configuration {
        Configuration(standard: PrismaStandard()) {
            if !FeatureFlags.disableFirebase {
                AccountConfiguration(configuration: [
                    .requires(\.userId),
                    .requires(\.name)
                ])
                
                if FeatureFlags.useFirebaseEmulator {
                    FirebaseAccountConfiguration(
                        authenticationMethods: [.emailAndPassword, .signInWithApple],
                        emulatorSettings: (host: "localhost", port: 9099)
                    )
                } else {
                    FirebaseAccountConfiguration(authenticationMethods: [.emailAndPassword, .signInWithApple])
                }
                firestore
                if FeatureFlags.useFirebaseEmulator {
                    FirebaseStorageConfiguration(emulatorSettings: (host: "localhost", port: 9199))
                } else {
                    FirebaseStorageConfiguration()
                }
            } else {
                MockWebService()
            }
            
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            PrismaScheduler()
            OnboardingDataSource()
            PrismaPushNotifications()
            PrivacyModule(sampleTypeList: sampleList)
        }
    }
    
    
    private var firestore: Firestore {
        let settings = FirestoreSettings()
        if FeatureFlags.useFirebaseEmulator {
            settings.host = "localhost:8080"
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
        }
        
        return Firestore(
            settings: settings
        )
    }
    
    private var healthKit: HealthKit {
        HealthKit {
            CollectSamples(
            // https://developer.apple.com/documentation/healthkit/data_types#2939032
                Set(sampleList),
                /// predicate to request data from one month in the past to present.
                predicate: HKQuery.predicateForSamples(
                    withStart: Calendar.current.date(byAdding: .month, value: -1, to: .now),
                    end: nil,
                    options: .strictEndDate
                ),
                deliverySetting: .anchorQuery(.afterAuthorizationAndApplicationWillLaunch)
            )
        }
    }
    
    
    /// When the app successfully registers for remote notifications, it receives a device
    /// token from Apple's push notification service (APNs). The deviceToken parameter
    /// contains a unique identifier for the device, which the app uses to receive remote
    /// notifications.
    ///
    /// We assign the APNs token received from Apple to the apnsToken property of the
    /// Messaging class provided by the Firebase SDK. Firebase uses this token to communicate with
    /// APNs and send notifications to the device.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
