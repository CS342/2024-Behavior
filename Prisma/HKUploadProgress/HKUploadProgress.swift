//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
//  Created by Bryant Jimenez on 3/28/24.
//

import SwiftUI

struct HKUploadProgressView: View {
    @Binding var presentingAccount: Bool
    @State private var progress = 0.5 // replace with progress from the actual upload
    
    var body: some View {
        NavigationStack {
            Spacer()
            VStack {
                Text("HealthKit Data Upload Progress")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .padding()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                GeometryReader { geometry in
                    Spacer()
                    ProgressView(value: progress)
                        .progressViewStyle(ProgressBarStyle())
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.05, alignment: .center)
                        .padding()
                    Spacer()
                }
            }
            .toolbar {
                if AccountButton.shouldDisplay {
                    AccountButton(isPresented: $presentingAccount)
                }
            }
        }
    }
}


struct ProgressBarStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.secondary.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Rectangle()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

#if DEBUG
#Preview {
    HKUploadProgressView(presentingAccount: .constant(false))
}
#endif
