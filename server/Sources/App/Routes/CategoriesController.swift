import Vapor

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("categories", use: self.index)
    }

    func index(req: Request) async throws -> Response {
        let encoded = try JSONEncoder().encode(req.application.categoryStore.all())
        return Response(
            status: .ok,
            headers: ["Content-Type": "application/json"],
            body: .init(data: encoded)
        )
    }
}
