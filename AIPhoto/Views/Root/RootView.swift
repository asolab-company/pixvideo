import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasPremiumAccess") private var hasPremiumAccess = false
    @StateObject private var storeKit = StoreKitPurchaseManager()
    @State private var onboardingPage: OnboardingPage = .video
    @State private var hasDismissedPaywallForCurrentLaunch = false
    @State private var isManualPaywallPresented = false

    var body: some View {
        appFlow
        .task {
            await storeKit.loadProducts()
            await storeKit.refreshPurchasedProducts()
            syncPremiumAccess(storeKit.hasPremiumAccess)
        }
        .onChange(of: storeKit.hasPremiumAccess) { _, hasPremiumAccess in
            syncPremiumAccess(hasPremiumAccess)
        }
        .fullScreenCover(isPresented: $isManualPaywallPresented) {
            PaywallView(
                presentationMode: .manual,
                priceText: storeKit.monthlyPriceText,
                originalPriceText: storeKit.monthlyOriginalPriceText,
                isPurchasing: storeKit.isPurchasing || storeKit.isLoadingProducts,
                errorMessage: storeKit.errorMessage,
                onStartCreating: startSubscriptionPurchase,
                onSkip: closeManualPaywall,
                onRestore: restoreSubscription,
                onDismissError: storeKit.dismissError
            )
        }
    }

    @ViewBuilder
    private var appFlow: some View {
        if !hasCompletedOnboarding {
            OnboardingFlowView(currentPage: $onboardingPage, onContinue: advanceOnboarding)
        } else if !hasPremiumAccess && !hasDismissedPaywallForCurrentLaunch {
            PaywallView(
                presentationMode: .automatic,
                priceText: storeKit.monthlyPriceText,
                originalPriceText: storeKit.monthlyOriginalPriceText,
                isPurchasing: storeKit.isPurchasing || storeKit.isLoadingProducts,
                errorMessage: storeKit.errorMessage,
                onStartCreating: startSubscriptionPurchase,
                onSkip: openMainAppForCurrentLaunch,
                onRestore: restoreSubscription,
                onDismissError: storeKit.dismissError
            )
        } else {
            MainAppView(
                hasPremiumAccess: hasPremiumAccess,
                onShowPaywall: showPaywallFromSettings,
                onRestorePurchases: restoreSubscription,
                onDeleteUserData: resetAppData
            )
        }
    }

    private func advanceOnboarding() {
        let pages = OnboardingPage.allCases
        guard let currentIndex = pages.firstIndex(of: onboardingPage) else {
            onboardingPage = .video
            return
        }

        let nextIndex = pages.index(after: currentIndex)
        if nextIndex < pages.endIndex {
            onboardingPage = pages[nextIndex]
        } else {
            hasCompletedOnboarding = true
            hasDismissedPaywallForCurrentLaunch = false
        }
    }

    private func openMainAppForCurrentLaunch() {
        hasDismissedPaywallForCurrentLaunch = true
    }

    private func showPaywallFromSettings() {
        guard !hasPremiumAccess else { return }
        isManualPaywallPresented = true
    }

    private func closeManualPaywall() {
        isManualPaywallPresented = false
    }

    private func startSubscriptionPurchase() {
        Task {
            let didPurchase = await storeKit.purchaseMonthly()
            if didPurchase {
                syncPremiumAccess(true)
            }
        }
    }

    private func restoreSubscription() {
        Task {
            let didRestore = await storeKit.restorePurchases()
            if didRestore {
                syncPremiumAccess(true)
            }
        }
    }

    private func syncPremiumAccess(_ isPremium: Bool) {
        hasPremiumAccess = isPremium
        if isPremium {
            hasDismissedPaywallForCurrentLaunch = true
            isManualPaywallPresented = false
        }
    }

    private func resetAppData() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }

        storeKit.resetCachedPremiumAccess()
        hasCompletedOnboarding = false
        hasPremiumAccess = false
        onboardingPage = .video
        hasDismissedPaywallForCurrentLaunch = false
        isManualPaywallPresented = false
    }
}

#Preview("Root") {
    RootView()
}
