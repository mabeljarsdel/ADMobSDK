//
//  InappManager.swift
//  EasyPhone
//
// Created by BBLabs on 11/01/2022.
//

import Foundation
import StoreKit
import SwiftyStoreKit
import AVFoundation
import RxSwift

public enum IAPState: String {
    case purchased = "purchased"
    case expired = "expired"
    case notPurchased = "notPurchased"
    case unload = "unload"
    
    public static var isDev = false
    private static let keyIAPState = "KEY_IAP_STATE"
    
    public static var iapState: IAPState {
        get {
            if let state = UserDefaults.standard.string(forKey: keyIAPState) {
                return IAPState(rawValue: state) ?? .notPurchased
            }
            return .notPurchased
        }
        set {
            if iapState != newValue {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: keyIAPState)
                print("--> send didPaymentSuccess")
                InappManager.share.didPaymentSuccess.onNext(newValue)
               
            }
        }
    }
    
    public static var isUserVip: Bool {
        return iapState == .purchased
    }
    
}

public typealias ProductIdentifier = String

public protocol InappManagerDelegate: AnyObject {
    func purchaseSuccess(id: String)
}

public class InappManager: NSObject {
    
    public static let share = InappManager()
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        SwiftyStoreKit.shouldAddStorePaymentHandler = { (payment: SKPayment, product: SKProduct) in
            return true
        }
    }
    
    private let sharedSecret: String = "973d30b0f2f845dc9f2cafe057b00dda"
    public var productIdentifiers: Set<ProductIdentifier> = Set()
    public var listProduct = Set<SKProduct>()
    public var didPaymentSuccess = BehaviorSubject<IAPState>(value: .unload)
    public var productsInfo = BehaviorSubject<[SKProduct]>(value: [])
    public var purchasedProduct: ProductIdentifier?
    public var infoPurchaseProduct: ReceiptItem?
    private var needShowRestoreError = false
    public weak var delegate: InappManagerDelegate?
    
    public func getFreedaysTrial(id: String) -> Int {
        var freeDay = 0
        if let subcription = InappManager.share.listProduct.first(where: {$0.productIdentifier == id})?.introductoryPrice?.subscriptionPeriod {
            switch subcription.unit {
            case .day:
                freeDay = subcription.numberOfUnits
            case .week:
                freeDay = subcription.numberOfUnits * 7
            default:
                freeDay = 3
            }
        }
        return freeDay
    }
    
    public func getPrice(id: String) -> String {
        if let subscription = InappManager.share.listProduct.first(where: {
            $0.productIdentifier == id
        }) {
            return subscription.regularPrice ?? ""
        }
        return ""
    }
    
    public func getPriceLocale(id: String) -> Locale {
        if let subscription = InappManager.share.listProduct.first(where: {
            $0.productIdentifier == id
        }) {
            return subscription.priceLocale
        }
        return Locale.current
    }
    
    public func getPriceNumb(id: String) -> NSDecimalNumber {
        if let subscription = InappManager.share.listProduct.first(where: {
            $0.productIdentifier == id
        }) {
            return subscription.price
        }
        return 0
    }
    
    public func getDiscountPrice(id: String) -> String {
        if let subscription = InappManager.share.listProduct.first(where: {
            $0.productIdentifier == id
        }) {
            return subscription.discounts.first?.regularPrice ?? ""
        }
        return ""
    }
    
    public func getDiscountPriceLocale(id: String) -> Locale {
        if let subscription = InappManager.share.listProduct.first(where: {
            $0.productIdentifier == id
        }) {
            return subscription.discounts.first?.priceLocale ?? Locale.current
        }
        return Locale.current
    }
    
    public func getDiscountPriceNumb(id: String) -> NSDecimalNumber {
        if let subscription = InappManager.share.listProduct.first(where: {
            $0.productIdentifier == id
        }) {
            return subscription.discounts.first?.price ?? 0
        }
        return 0
    }
    
    public func checkPurchaseProduct() {
        SwiftyStoreKit.completeTransactions(atomically: true) { [weak self] purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    self?.purchasedProduct = purchase.productId
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                case .failed, .purchasing, .deferred:
                    break
                default:
                    break
                }
            }
        }
    }
    
    public func purchaseProduct(withId id: String) {
        guard let product = listProduct.first(where: { $0.productIdentifier == id }) else { return }
        if SKPaymentQueue.canMakePayments() {
            LoadingProgressHUD.show()
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    public func productInfo(id: Set<String>, isShowLoading: Bool = true,
                     completed: @escaping(Set<SKProduct>) -> () = {_ in}) -> InAppRequest {
        if isShowLoading {
            LoadingProgressHUD.show()
        }
        return SwiftyStoreKit.retrieveProductsInfo(id) { [weak self] result in
            LoadingProgressHUD.dismiss()
            if !result.retrievedProducts.isEmpty {
                self?.listProduct = result.retrievedProducts
                self?.productsInfo.onNext(result.retrievedProducts.map { $0 })
                DispatchQueue.main.async {
                    completed(result.retrievedProducts)
                }
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId) with error: \(result.error)")
                IAPState.iapState = .unload
                DispatchQueue.main.async {
                    completed([])
                }
            }
            else {
                IAPState.iapState = .unload
                print("Error: \(result.error!)")
                DispatchQueue.main.async {
                    completed([])
                }
            }
        }
    }
    
    // MARK: Restore
    public func restorePurchases(isShowLoading: Bool = true) {
        if (SKPaymentQueue.canMakePayments()) {
            if isShowLoading {
                LoadingProgressHUD.show()
            }
            needShowRestoreError = isShowLoading
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
    }
    
    // MARK: Tự động Gia hạn
    public func veryCheckRegisterPack(completed: @escaping() -> ()) -> InAppRequest? {
        let appleValidator = AppleReceiptValidator(service: IAPState.isDev ? .sandbox : .production , sharedSecret: self.sharedSecret)
        return SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: true) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: .autoRenewable, productIds: self.productIdentifiers, inReceipt: receipt)
                switch purchaseResult {
                case .purchased( let expireddate, let items):
                    print("==> purchased expireddate \(expireddate)")
                    IAPState.iapState = .purchased
                    self.infoPurchaseProduct = items.first
                    self.purchasedProduct = items.first?.productId
                case .expired(let expireddate,_):
                    print("==> expireddate \(expireddate)")
                    IAPState.iapState = .expired
                case .notPurchased:
                    IAPState.iapState = .notPurchased
                }
                completed()
            case .error:
                IAPState.iapState = .notPurchased
                completed()
            }
            
        }
    }
    
    public func getInfoPurchasedProduct() {
        let appleValidator = AppleReceiptValidator(service: IAPState.isDev ? .sandbox : .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: true) { result in
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: .autoRenewable, productIds: self.productIdentifiers, inReceipt: receipt)
                switch purchaseResult {
                case .purchased(_, let items):
                    self.infoPurchaseProduct = items.first
                default:
                    break
                }
            case .error(let error):
                print("Verify receipt failed: \(error)")
            }
        }
    }
    
}

// MARK: - SKPaymentTransactionObserver
extension InappManager: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                LoadingProgressHUD.dismiss()
                purchasedProduct = transaction.payment.productIdentifier
                IAPState.iapState = .purchased
                SKPaymentQueue.default().finishTransaction(transaction as SKPaymentTransaction)
            case .failed:
                print("Purchased Failed")
                LoadingProgressHUD.dismiss()
                SKPaymentQueue.default().finishTransaction(transaction as SKPaymentTransaction)
            default:
                break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if needShowRestoreError {
//            AppRouter.shared.rootViewController?.createToast(type: .error, title: error.localizedDescription)
        }
        LoadingProgressHUD.dismiss()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        let appleValidator = AppleReceiptValidator(service: IAPState.isDev ? .sandbox : .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { [weak self] result in
            LoadingProgressHUD.dismiss()
            guard let self = self else { return }
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: .autoRenewable, productIds: self.productIdentifiers, inReceipt: receipt)
                switch purchaseResult {
                case .purchased( _, let items):
                    self.infoPurchaseProduct = items.first
                    self.purchasedProduct = items.first?.productId
                    IAPState.iapState = .purchased
                    self.delegate?.purchaseSuccess(id: "")
                case .expired(_,_):
                    IAPState.iapState = .expired
                case .notPurchased:
                    IAPState.iapState = .notPurchased
                    break
                }
            case .error(let error):
                print("verify faild \(error.localizedDescription)")
            }
        }
        for transaction in queue.transactions {
            SKPaymentQueue.default().finishTransaction(transaction as SKPaymentTransaction)
        }
    }
}

extension SKProduct {
    
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
    
}

extension SKProductDiscount {
    
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
    
}
