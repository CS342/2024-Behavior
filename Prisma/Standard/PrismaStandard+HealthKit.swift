//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import HealthKitOnFHIR
import ModelsR4
import SpeziFirestore
import SpeziHealthKit


extension PrismaStandard: BulkUploadConstraint {
    /// Notifies the `Standard` about the addition of a batch of HealthKit ``HKSample`` samples instance.
    /// - Parameter samplesAdded: The batch of `HKSample`s that should be added.
    /// - Parameter objectsDeleted: The batch of `HKSample`s that were deleted from the HealthStore. Included if needed to account for rate limiting
    /// when uploading to a cloud provider.
    func processBulk(samplesAdded: [HKSample], samplesDeleted: [HKDeletedObject]) async {
        
        for hkSample in samplesAdded {
            await add(sample: <#T##HKSample#>)
        }
    }
    
    /// Adds a new `HKSample` to the Firestore.
    /// - Parameter response: The `HKSample` that should be added.
    func add(sample: HKSample) async {
        guard let collectDataTypes = privacyModule?.collectDataTypes else {
            return
        }
        
        // Only upload types that the user gave permission for.
        guard collectDataTypes[sample.sampleType] ?? false else {
            return
        }
        
        // convert the startDate of the HKSample to local time
        let timeIndex = Date.constructTimeIndex(startDate: sample.startDate, endDate: sample.endDate)
        let effectiveTimestamp = sample.startDate.toISOFormat()
        
        let path: String
        // path = HEALTH_KIT_PATH/raw/YYYY-MM-DDThh:mm:ss.mss
        do {
            path = try await getPath(module: .health(sample.sampleType.identifier)) + "raw/\(effectiveTimestamp)"
        } catch {
            print("Failed to define path: \(error.localizedDescription)")
            return
        }
        
        // try push to Firestore.
        do {
            let deviceName = sample.sourceRevision.source.name
            let resource = try sample.resource
            let encoder = FirebaseFirestore.Firestore.Encoder()
            // encoder is used to convert swift types to a format that can be stored in firestore
            var firestoreResource = try encoder.encode(resource)
            firestoreResource["device"] = deviceName
            // timeIndex is a dictionary with time-related info (range, timezone, datetime.start, datetime.end)
            // timeIndex is added a field for this specific HK datapoint so we can just access this part to fetch/sort by time
            firestoreResource["time"] = timeIndex
            firestoreResource["datetimeStart"] = effectiveTimestamp
            try await Firestore.firestore().document(path).setData(firestoreResource)
        } catch {
            logger.warning("Failed to set data in Firestore: \(error.localizedDescription)")
        }
    }
    
    func remove(sample: HKDeletedObject) async {}
    
    
    func toggleHideFlag(sampleType: HKSampleType, documentId: String, alwaysHide: Bool) async throws {
        let firestore = Firestore.firestore()
        let path: String
        
        do {
            // call getPath to get the path for this user, up until this specific quantityType
            path = try await getPath(module: .health(sampleType.identifier)) + "raw/\(documentId)"
            logger.debug("Selected identifier: \(sampleType.identifier)")
            logger.debug("Path from getPath: \(path)")
        } catch {
            logger.error("Failed to define path: \(error.localizedDescription)")
            throw error
        }
        
        do {
            let document = firestore.document(path)
            let docSnapshot = try await document.getDocument()
            
            // If hideFlag exists, update its value
            if let hideFlagExists = docSnapshot.data()?["hideFlag"] as? Bool {
                if alwaysHide {
                    // If alwaysHide is true, always set hideFlag to true regardless of original value
                    try await document.setData(["hideFlag": true], merge: true)
                    logger.debug("AlwaysHide is enabled; set hideFlag to true.")
                } else {
                    // Toggle hideFlag if alwaysHide is not true
                    try await document.setData(["hideFlag": !hideFlagExists], merge: true)
                    logger.debug("Toggled hideFlag to \(!hideFlagExists).")
                }
            } else {
                // If hideFlag does not exist, create it and set to true
                try await document.setData(["hideFlag": true], merge: true)
                logger.debug("hideFlag was missing; set to true.")
            }
        } catch {
            logger.error("Failed to set data in Firestore: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchRecentSamples(for sampleType: HKSampleType, limit: Int = 50) async -> [QueryDocumentSnapshot] {
        guard !ProcessInfo.processInfo.isPreviewSimulator else {
            return []
        }
        
        do {
            let path = try await getPath(module: .health(sampleType.identifier)) + "raw/"
            logger.debug("Selected identifier: \(sampleType.identifier)")
            logger.debug("Path from getPath: \(path)")
            
            #warning("The logic should ideally not be based on the issued date but rather datetimeStart once this is reflected in the mock data.")
            let querySnapshot = try await Firestore
                .firestore()
                .collection(path)
                .order(by: "issued", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return querySnapshot.documents
        } catch {
            logger.error("Failed to fetch documents or define path: \(error.localizedDescription)")
            return []
        }
    }
    
    // Fetches timestamp based on documentID date
    func hideSamples(sampleType: HKSampleType, startDate: Date, endDate: Date) async {
        do {
            let path = try await getPath(module: .health(sampleType.identifier)) + "raw/"
            logger.debug("Selected identifier: \(sampleType.identifier)")
            logger.debug("Path from getPath: \(path)")
            
            #warning("The logic should ideally not be based on the issued date but rather datetimeStart once this is reflected in the mock data.")
            let querySnapshot = try await Firestore
                .firestore()
                .collection(path)
                .whereField("issued", isGreaterThanOrEqualTo: startDate.toISOFormat())
                .whereField("issued", isLessThanOrEqualTo: endDate.toISOFormat())
                .getDocuments()
            
            #warning("This execution is slow. We should have a clound function or backend endpoint for this.")
            for document in querySnapshot.documents {
                try await toggleHideFlag(sampleType: sampleType, documentId: document.documentID, alwaysHide: true)
            }
        } catch {
            if let firestoreError = error as? FirestoreError {
                logger.error("Error fetching documents: \(firestoreError.localizedDescription)")
            } else {
                logger.error("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
}
