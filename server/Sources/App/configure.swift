import Vapor
import Foundation

public func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    guard
        let listingsURL = Bundle.module.url(forResource: "listings", withExtension: "json", subdirectory: "Seed"),
        let categoriesURL = Bundle.module.url(forResource: "categories", withExtension: "json", subdirectory: "Seed")
    else {
        throw Abort(.internalServerError, reason: "Seed files not found")
    }

    let listings = try decoder.decode([Listing].self, from: Data(contentsOf: listingsURL))
    let categories = try decoder.decode([Category].self, from: Data(contentsOf: categoriesURL))

    app.listingStore.seed(from: listings)
    app.categoryStore.seed(from: categories)

    try app.register(collection: CategoriesController())
    try app.register(collection: ListingsController())
}
