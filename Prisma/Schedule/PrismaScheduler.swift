//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziScheduler


/// A `Scheduler` using the ``PrismaTaskContext`` to schedule and manage tasks and events in the
/// Prisma.
typealias PrismaScheduler = Scheduler<PrismaTaskContext>

/// These are placeholder surveys that should be replaced with project-relevant surveys later!
extension PrismaScheduler {
    convenience init() {
        self.init(
            tasks: []
        )
    }
}
