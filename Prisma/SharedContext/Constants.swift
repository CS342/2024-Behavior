//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum Constants {
    static var hostname: URL = {
        let hostname: URL?
        if FeatureFlags.useFirebaseEmulator {
            hostname = URL(string: "http://localhost:3000")
        } else {
            #warning("Needs to be replaced with the deployed PRISMA web service & frontend.")
            hostname = URL(string: "https://prisma.stanford.edu")
        }
        
        guard let hostname else {
            fatalError("Could not construct Constants.hostname")
        }
        
        return hostname
    }()
    
//    static let keyChainGroup = "637867499T.edu.stanford.cs342.2024.behavior"
    static let keyChainGroup = "64FJ2MWNP4.edu.stanford.prisma"
}
