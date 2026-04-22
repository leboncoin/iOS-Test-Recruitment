import XCTVapor
@testable import App

final class CategoriesTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try configure(self.app)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
    }

    func testGetCategoriesReturnsAll() async throws {
        let tester: XCTApplicationTester = try self.app.testable()
        try await tester.test(.GET, "/categories", afterResponse: { (res: XCTHTTPResponse) async throws in
            XCTAssertEqual(res.status, .ok)
            let categories = try res.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, self.app.categoryStore.all().count)
        })
    }

    func testCategoryHasIdAndName() async throws {
        let tester: XCTApplicationTester = try self.app.testable()
        try await tester.test(.GET, "/categories", afterResponse: { (res: XCTHTTPResponse) async throws in
            let categories = try res.content.decode([App.Category].self)
            for category in categories {
                XCTAssertGreaterThan(category.id, 0)
                XCTAssertFalse(category.name.isEmpty)
            }
        })
    }
}
