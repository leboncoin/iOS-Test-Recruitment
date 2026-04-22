import Vapor

struct ListingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let listings = routes.grouped("listings")
        listings.get(use: self.index)
    }

    func index(req: Request) async throws -> Response {
        let query = req.query[String.self, at: "query"]
        let requestedPage = req.query[Int.self, at: "page"]
        let requestedLimit = req.query[Int.self, at: "limit"]

        if (requestedPage == nil) != (requestedLimit == nil) {
            throw Abort(.badRequest, reason: "page and limit must be provided together")
        }
        if let requestedPage = requestedPage, requestedPage <= 0 {
            throw Abort(.badRequest, reason: "page must be greater than 0")
        }
        if let requestedLimit = requestedLimit, requestedLimit <= 0 {
            throw Abort(.badRequest, reason: "limit must be greater than 0")
        }

        let store = req.application.listingStore
        let result = store.allWithTotal(page: requestedPage, limit: requestedLimit, query: query)
        let dtos = result.items.map { ListingResponse(from: $0) }
        let responsePage = requestedPage ?? 1
        let responseLimit = requestedLimit ?? result.items.count
        let hasMore = requestedPage != nil && requestedLimit != nil && (responsePage * responseLimit) < result.total

        let response = ListingFeedResponse(
            total: result.total,
            page: responsePage,
            limit: responseLimit,
            hasMore: hasMore,
            items: dtos
        )
        let encoded = try JSONEncoder().encode(response)
        return Response(
            status: .ok,
            headers: ["Content-Type": "application/json"],
            body: .init(data: encoded)
        )
    }
}
