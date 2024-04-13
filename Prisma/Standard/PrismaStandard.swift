//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import OSLog
import Spezi
import SpeziAccount
import SpeziFirebaseAccountStorage


actor PrismaStandard: Standard, EnvironmentAccessible {
    enum PrismaStandardError: Error {
        case userNotAuthenticatedYet
    }
    
    /// modify this study id to change the Firebase bucket.
    static let STUDYID = "tech-probe"
    
    static var userCollection: CollectionReference {
        Firestore.firestore().collection("studies").document(STUDYID).collection("users")
    }
    
    @Dependency var accountStorage: FirestoreAccountStorage?
    @Dependency var privacyModule: PrivacyModule?
    @AccountReference var account: Account
    
    let logger = Logger(subsystem: "Prisma", category: "Standard")
    
    
    init() {
        if !FeatureFlags.disableFirebase {
            _accountStorage = Dependency(wrappedValue: FirestoreAccountStorage(storeIn: PrismaStandard.userCollection))
        }
    }
}
