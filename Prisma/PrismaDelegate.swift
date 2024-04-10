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
import SpeziOnboarding
import SpeziScheduler
import SwiftUI


class PrismaDelegate: SpeziAppDelegate {
    // https://developer.apple.com/documentation/healthkit/data_types#2939032
    static let healthKitSampleTypes = [
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
                    if FeatureFlags.healthKitUploadOnly {
                        FirebaseAccountConfiguration(authenticationMethods: [.emailAndPassword])
                    } else {
                        FirebaseAccountConfiguration(authenticationMethods: [.emailAndPassword, .signInWithApple])
                    }
                }
                firestore
                if FeatureFlags.useFirebaseEmulator {
                    FirebaseStorageConfiguration(emulatorSettings: (host: "localhost", port: 9199))
                } else {
                    FirebaseStorageConfiguration()
                }
            }
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            PrismaScheduler()
            OnboardingDataSource()
            PrismaPushNotifications()
            PrivacyModule(sampleTypes: PrismaDelegate.healthKitSampleTypes)
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
            BulkUpload(
                Set(PrismaDelegate.healthKitSampleTypes),
                /// predicate to request data from one month in the past to present.
                predicate: HKQuery.predicateForSamples(
                    withStart: Calendar.current.date(byAdding: .month, value: -1, to: .now),
                    end: Date(),
                    options: .strictEndDate
                ),
                bulkSize: 500,
                deliveryStartSetting: .automatic
            )
            CollectSamples(
                Set(PrismaDelegate.healthKitSampleTypes),
                deliverySetting: .anchorQuery(.automatic)
            )
        }
    }
}
