import Foundation
import XCTVapor
@testable import App

final class ListingsTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try configure(self.app)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
    }

    func testGetListingsReturnsStableEnvelope() async throws {
        try await self.app.test(.GET, "/listings", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .ok)
            let feed = try res.content.decode(ListingFeedResponse.self)
            XCTAssertEqual(feed.total, self.app.listingStore.allWithTotal().total)
            XCTAssertEqual(feed.page, 1)
            XCTAssertEqual(feed.limit, feed.total)
            XCTAssertFalse(feed.hasMore)
            XCTAssertEqual(feed.items.count, feed.total)
            self.assertListingsAreSorted(feed.items)
        })
    }

    func testGetListingsPaginatedMatchesFirstPageOfFullFeed() async throws {
        let fullFeed = try await self.fetchFeed("/listings")

        try await self.app.test(.GET, "/listings?page=1&limit=20", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .ok)
            let feed = try res.content.decode(ListingFeedResponse.self)
            XCTAssertEqual(feed.items.count, 20)
            XCTAssertEqual(feed.total, self.app.listingStore.allWithTotal().total)
            XCTAssertEqual(feed.page, 1)
            XCTAssertEqual(feed.limit, 20)
            XCTAssertTrue(feed.hasMore)
            self.assertListingsAreSorted(feed.items)
            XCTAssertEqual(feed.items.map(\.id), Array(fullFeed.items.prefix(20)).map(\.id))
        })
    }

    func testGetListingsPaginatedPage2DoesNotDuplicatePage1() async throws {
        let firstPage = try await self.fetchFeed("/listings?page=1&limit=20")
        let secondPage = try await self.fetchFeed("/listings?page=2&limit=20")
        let totalListings = self.app.listingStore.allWithTotal().total

        XCTAssertEqual(firstPage.total, totalListings)
        XCTAssertEqual(secondPage.total, totalListings)
        XCTAssertTrue(firstPage.hasMore)
        XCTAssertTrue(secondPage.hasMore)
        XCTAssertTrue(Set(firstPage.items.map(\.id)).isDisjoint(with: Set(secondPage.items.map(\.id))))
    }

    func testSearchReturnsStableEnvelope() async throws {
        try await self.app.test(.GET, "/listings?query=iphone", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .ok)
            let feed = try res.content.decode(ListingFeedResponse.self)
            XCTAssertEqual(feed.page, 1)
            XCTAssertEqual(feed.limit, feed.items.count)
            XCTAssertFalse(feed.hasMore)
            XCTAssertGreaterThan(feed.items.count, 0)
            self.assertListingsAreSorted(feed.items)
            for listing in feed.items {
                let matchesTitle = listing.title.lowercased().contains("iphone")
                let matchesDescription = listing.description.lowercased().contains("iphone")
                XCTAssertTrue(matchesTitle || matchesDescription)
            }
        })
    }

    func testPageWithoutLimitReturns400() async throws {
        try await self.app.test(.GET, "/listings?page=1", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testLimitWithoutPageReturns400() async throws {
        try await self.app.test(.GET, "/listings?limit=20", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testInvalidPageReturns400() async throws {
        try await self.app.test(.GET, "/listings?page=0&limit=20", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testInvalidLimitReturns400() async throws {
        try await self.app.test(.GET, "/listings?page=1&limit=0", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testSeededImageURLsAreLocalFixturePaths() throws {
        let listings = self.app.listingStore.allWithTotal().items
        let urls = listings.compactMap(\.imagesUrl).flatMap { [$0.small, $0.thumb] }.compactMap { $0 }

        XCTAssertFalse(urls.isEmpty)
        XCTAssertTrue(urls.allSatisfy { $0.hasPrefix("/images/") })
        XCTAssertFalse(urls.contains(where: { $0.contains("raw.githubusercontent.com") }))
    }

    func testSeededImageFixtureFilesExistExceptIntentionalBrokenCases() throws {
        let listings = self.app.listingStore.allWithTotal().items
        let smallURLs = listings.compactMap(\.imagesUrl?.small)
        let thumbURLs = listings.compactMap(\.imagesUrl?.thumb)
        let poisonedSmall = smallURLs.filter { $0.hasSuffix("/poisoned-image.jpg") }
        let poisonedThumb = thumbURLs.filter { $0.hasSuffix("/poisoned-image.jpg") }

        XCTAssertEqual(poisonedSmall.count, 5)
        XCTAssertEqual(poisonedThumb.count, 5)

        for url in smallURLs where !url.hasSuffix("/poisoned-image.jpg") {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: self.publicFilePath(for: url)),
                "Missing fixture file for \(url)"
            )
        }

        for url in thumbURLs where !url.hasSuffix("/poisoned-image.jpg") {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: self.publicFilePath(for: url)),
                "Missing fixture file for \(url)"
            )
        }
    }

    func testValidSeededImageIsServedByTheAPI() async throws {
        let imageURL = try XCTUnwrap(
            self.app.listingStore.allWithTotal().items
                .compactMap(\.imagesUrl?.small)
                .first(where: { !$0.hasSuffix("/poisoned-image.jpg") })
        )

        try await self.app.test(.GET, imageURL, afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssertGreaterThan(res.body.readableBytes, 0)
        })
    }

    func testIntentionalBrokenSeededImageReturns404() async throws {
        let imageURL = try XCTUnwrap(
            self.app.listingStore.allWithTotal().items
                .compactMap(\.imagesUrl?.small)
                .first(where: { $0.hasSuffix("/poisoned-image.jpg") })
        )

        try await self.app.test(.GET, imageURL, afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .notFound)
        })
    }

    private func fetchFeed(_ path: String) async throws -> ListingFeedResponse {
        var response: ListingFeedResponse?
        try await self.app.test(.GET, path, afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .ok)
            response = try res.content.decode(ListingFeedResponse.self)
        })
        return try XCTUnwrap(response)
    }

    private func assertListingsAreSorted(
        _ listings: [ListingResponse],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let formatter = ISO8601DateFormatter()

        for (current, next) in zip(listings, listings.dropFirst()) {
            if current.isUrgent != next.isUrgent {
                XCTAssertTrue(current.isUrgent, file: file, line: line)
                XCTAssertFalse(next.isUrgent, file: file, line: line)
                continue
            }

            guard
                let currentDate = formatter.date(from: current.creationDate),
                let nextDate = formatter.date(from: next.creationDate)
            else {
                XCTFail("Could not parse listing creation dates", file: file, line: line)
                return
            }

            XCTAssertGreaterThanOrEqual(currentDate, nextDate, file: file, line: line)
        }
    }

    private func publicFilePath(for url: String) -> String {
        let relativePath = url.hasPrefix("/") ? String(url.dropFirst()) : url
        return URL(fileURLWithPath: self.app.directory.workingDirectory)
            .appendingPathComponent("Public", isDirectory: true)
            .appendingPathComponent(relativePath)
            .path
    }
}
