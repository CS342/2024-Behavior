//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SpeziAccount
import SpeziFirebaseAccountStorage


extension PrismaStandard: AccountStorageConstraint {
    var userDocumentReference: DocumentReference {
        get async throws {
            guard let details = await account.details else {
                throw PrismaStandardError.userNotAuthenticatedYet
            }

            return Self.userCollection.document(details.accountId)
        }
    }
    
    /// The firestore path for a given `Module`.
    /// - Parameter module: The `Module` that is requested.
    func getPath(module: PrismaModule) async throws -> String {
        let accountId: String
        if FeatureFlags.disableFirebase {
            accountId = "USER_ID"
        } else {
            guard let firebaseId = Auth.auth().currentUser?.uid else {
                throw PrismaStandardError.userNotAuthenticatedYet
            }
            accountId = firebaseId
        }
        
        /// the "MODULE/SUBTYPE" string.
        var moduleText: String
        
        switch module {
        case .questionnaire(let type):
            // Questionnaire responses
            moduleText = "\(module.description)/\(type)"
        case .health(let type):
            // HealthKit observations
            moduleText = "\(module.description)/\(type.healthKitDescription)"
        case .notifications(let type):
            // notifications for user, type either "logs" or "schedule"
            moduleText = "\(module.description)/data/\(type)"
        }
        // studies/STUDY_ID/users/USER_ID/MODULE_NAME/SUB_TYPE/...
        return "studies/\(PrismaStandard.STUDYID)/users/\(accountId)/\(moduleText)/"
    }
    
    
    // MARK: - Account State Handling
    /// Authorizes access to the Prisma keychain access group for the currently signed-in user.
    ///
    /// If the current user is signed in, this function authorizes their access to the Prisma notifications keychain access group identifier.
    /// If the user is not signed in, or if an error occurs during the authorization process, appropriate error handling is performed, and the user may be logged out.
    ///
    /// - Parameters:
    ///   - user: The current user object.
    ///   - accessGroup: The identifier of the access group to authorize.
    ///
    /// - Throws: An error if an issue occurs during the authorization process.
    func authorizeAccessGroupForCurrentUser() async {
        guard let user = Auth.auth().currentUser else {
            logger.warning("No signed in user.")
            return
        }
        
        guard (try? Auth.auth().getStoredUser(forAccessGroup: Constants.keyChainGroup)) == nil else {
            logger.warning("Access group already shared ...")
            return
        }
        
        do {
            try Auth.auth().useUserAccessGroup(Constants.keyChainGroup)
            try await Auth.auth().updateCurrentUser(user)
        } catch let error as NSError {
            logger.error("Error changing user access group: %@ \(error)")
            // log out the user if fails
            try? Auth.auth().signOut()
        }
    }
    
    func deletedAccount() async throws {
        // delete all user associated data
        do {
            try await userDocumentReference.delete()
        } catch {
            logger.error("Could not delete user document: \(error)")
        }
    }
    
    
    // MARK: - Account Details
    func create(_ identifier: AdditionalRecordId, _ details: SignupDetails) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.create(identifier, details)
    }
    
    func setAccountTimestamp() async {
        // Add a "created_at" timestamp to the newly created user document
        let timestamp = Timestamp(date: Date())
        do {
            try await self.userDocumentReference.setData([
                "created_at": timestamp
            ], merge: true)
            logger.debug("Added timestamp to user document")
        } catch {
            logger.error("Error updating document: \(error)")
        }
    }

    func load(_ identifier: AdditionalRecordId, _ keys: [any AccountKey.Type]) async throws -> PartialAccountDetails {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        return try await accountStorage.load(identifier, keys)
    }

    func modify(_ identifier: AdditionalRecordId, _ modifications: AccountModifications) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.modify(identifier, modifications)
    }

    func clear(_ identifier: AdditionalRecordId) async {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        await accountStorage.clear(identifier)
    }

    func delete(_ identifier: AdditionalRecordId) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.delete(identifier)
    }
}
