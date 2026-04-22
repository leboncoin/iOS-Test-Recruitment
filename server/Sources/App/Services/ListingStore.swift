import Vapor
import Foundation

final class ListingStore: @unchecked Sendable {
    private var listings: [Listing] = []
    private let lock = NSLock()

    func seed(from listings: [Listing]) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.listings = listings
    }

    // Private helpers — callers must hold self.lock
    private func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func applyFilter(_ listings: [Listing], query: String?) -> [Listing] {
        guard let rawQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines), !rawQuery.isEmpty else {
            return listings
        }

        let normalizedQuery = self.normalize(rawQuery)
        return listings.filter {
            self.normalize($0.title).contains(normalizedQuery) || self.normalize($0.description).contains(normalizedQuery)
        }
    }

    private func applySort(_ listings: [Listing]) -> [Listing] {
        listings.sorted {
            if $0.isUrgent != $1.isUrgent {
                return $0.isUrgent && !$1.isUrgent
            }

            if $0.creationDate != $1.creationDate {
                return $0.creationDate > $1.creationDate
            }

            return $0.id > $1.id
        }
    }

    func allWithTotal(page: Int? = nil, limit: Int? = nil, query: String? = nil) -> (items: [Listing], total: Int) {
        self.lock.lock()
        defer { self.lock.unlock() }
        let filtered = self.applySort(self.applyFilter(self.listings, query: query))
        let total = filtered.count
        guard let page = page, let limit = limit, page > 0, limit > 0 else {
            return (items: filtered, total: total)
        }
        let offset = (page - 1) * limit
        let paged = Array(filtered.dropFirst(offset).prefix(limit))
        return (items: paged, total: total)
    }
}

extension Application {
    struct ListingStoreKey: StorageKey {
        typealias Value = ListingStore
    }

    var listingStore: ListingStore {
        get {
            if let store = self.storage[ListingStoreKey.self] { return store }
            let store = ListingStore()
            self.storage[ListingStoreKey.self] = store
            return store
        }
        set { self.storage[ListingStoreKey.self] = newValue }
    }
}
