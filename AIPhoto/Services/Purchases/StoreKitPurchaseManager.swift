import Foundation
import StoreKit

@MainActor
final class StoreKitPurchaseManager: ObservableObject {
    static let monthlyProductID = AppConfiguration.Subscription.monthlyProductID

    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var hasPremiumAccess = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var errorMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    var monthlyPriceText: String {
        monthlyProduct?.displayPrice ?? "Loading..."
    }

    var monthlyOriginalPriceText: String {
        guard let monthlyProduct else { return "—" }

        var increasedPrice = monthlyProduct.price * AppConfiguration.Subscription.comparisonPriceMultiplier
        var roundedInteger = Decimal()
        NSDecimalRound(&roundedInteger, &increasedPrice, 0, .up)
        let appleStylePrice = max(
            monthlyProduct.price,
            roundedInteger - AppConfiguration.Subscription.appleStylePriceAdjustment
        )

        return appleStylePrice.formatted(monthlyProduct.priceFormatStyle)
    }

    init() {
        transactionUpdatesTask = listenForTransactionUpdates()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        errorMessage = nil
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [Self.monthlyProductID])
            monthlyProduct = products.first { $0.id == Self.monthlyProductID }
            if monthlyProduct == nil {
                errorMessage = "The subscription product \(Self.monthlyProductID) was not returned by StoreKit. Check the active StoreKit Configuration in the Run scheme."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchaseMonthly() async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        if monthlyProduct == nil {
            await loadProducts()
        }

        guard let monthlyProduct else {
            if errorMessage == nil {
                errorMessage = "Subscription product is unavailable."
            }
            return false
        }

        do {
            let result = try await monthlyProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPurchasedProducts()
                return hasPremiumAccess
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
            return hasPremiumAccess
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func refreshPurchasedProducts() async {
        var hasActiveSubscription = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            if transaction.productID == Self.monthlyProductID,
               transaction.revocationDate == nil {
                hasActiveSubscription = true
            }
        }

        hasPremiumAccess = hasActiveSubscription
    }

    func resetCachedPremiumAccess() {
        hasPremiumAccess = false
    }

    func dismissError() {
        errorMessage = nil
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = update else {
                    continue
                }

                await transaction.finish()
                await refreshPurchasedProducts()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreKitError.notAvailableInStorefront
        }
    }
}
