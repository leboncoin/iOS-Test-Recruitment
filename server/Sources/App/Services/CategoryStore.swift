import Vapor
import Foundation

final class CategoryStore: @unchecked Sendable {
    private var categories: [Category] = []
    private let lock = NSLock()

    func seed(from categories: [Category]) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.categories = categories.sorted { $0.id < $1.id }
    }

    func all() -> [Category] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.categories
    }

    func contains(id: Int) -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.categories.contains { $0.id == id }
    }
}

extension Application {
    struct CategoryStoreKey: StorageKey {
        typealias Value = CategoryStore
    }

    var categoryStore: CategoryStore {
        get {
            if let store = self.storage[CategoryStoreKey.self] {
                return store
            }

            let store = CategoryStore()
            self.storage[CategoryStoreKey.self] = store
            return store
        }
        set {
            self.storage[CategoryStoreKey.self] = newValue
        }
    }
}
