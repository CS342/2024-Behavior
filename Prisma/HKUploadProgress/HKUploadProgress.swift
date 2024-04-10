//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
// Created by Bryant Jimenez on 3/28/24.
//

import SwiftUI

struct ProgressBarStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color.secondary.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct HKUploadProgress: View {
    @Binding var presentingAccount: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PrismaPushNotifications.self) private var pushNotifications
    @State private var progress = 0.5 // replace with progress from the actual upload
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack {
                    Text("Upload Progress")
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .padding()
                    ProgressView(value: progress)
                        .progressViewStyle(ProgressBarStyle())
                        .frame(height: 20)
                        .padding(.horizontal)
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Spacer()
            }
            .toolbar {
                if AccountButton.shouldDisplay {
                    AccountButton(isPresented: $presentingAccount)
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .background {
                    pushNotifications.sendHealthKitUploadPausedNotification()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    HKUploadProgress(presentingAccount: .constant(false))
}
#endif
