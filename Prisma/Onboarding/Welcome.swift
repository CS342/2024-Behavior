//
// This source file is part of the Stanford Prisma Application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct Welcome: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    
    var body: some View {
        Group {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .center) {
                        title
                        if FeatureFlags.healthKitUploadOnly {
                            Image(.healthKitUploadIconNoBG)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 0.7 * geometry.size.width)
                                .accessibilityHidden(true)
                        } else {
                            Image(.appIconNoBackground)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 0.7 * geometry.size.width)
                                .accessibilityHidden(true)
                        }
                        Spacer()
                        description
                        Spacer()
                        OnboardingActionsView("WELCOME_BUTTON") {
                            onboardingNavigationPath.nextStep()
                        }
                        Spacer()
                            .frame(height: 10)
                    }
                        .frame(minHeight: geometry.size.height)
                }
            }
                .padding(24)
        }
    }
    
    var title: some View {
        if FeatureFlags.healthKitUploadOnly {
            return AnyView(
                Text("HealthKit Upload")
                .font(.system(size: 50))
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .padding()
                .multilineTextAlignment(.center)
            )
        } else {
            return AnyView(
                Text("PRISMA")
                .font(.system(size: 60))
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
            )
        }
    }
    
    var description: some View {
        VStack {
            Text("Welcome!")
                .font(.title)
                .fontWeight(.semibold)
                .opacity(0.7)
            Text("WELCOME_SUBTITLE")
                .padding([.top, .bottom])
        }
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        Welcome()
    }
}
#endif
