import Foundation

private let iso8601Formatter: ISO8601DateFormatter = ISO8601DateFormatter()

struct ListingResponse: Codable {
    let id: Int
    let categoryId: Int
    let title: String
    let description: String
    let price: Double
    let creationDate: String
    let isUrgent: Bool
    let imagesUrl: ImagesUrlDTO?

    struct ImagesUrlDTO: Codable {
        let small: String?
        let thumb: String?

        enum CodingKeys: String, CodingKey {
            case small, thumb
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price
        case categoryId = "category_id"
        case creationDate = "creation_date"
        case isUrgent = "is_urgent"
        case imagesUrl = "images_url"
    }

    init(from listing: Listing) {
        self.id = listing.id
        self.categoryId = listing.categoryId
        self.title = listing.title
        self.description = listing.description
        self.price = listing.price
        self.isUrgent = listing.isUrgent
        self.creationDate = iso8601Formatter.string(from: listing.creationDate)
        if let img = listing.imagesUrl {
            self.imagesUrl = ImagesUrlDTO(small: img.small, thumb: img.thumb)
        } else {
            self.imagesUrl = nil
        }
    }
}

struct ListingFeedResponse: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
    let items: [ListingResponse]

    enum CodingKeys: String, CodingKey {
        case total, page, limit, items
        case hasMore = "has_more"
    }
}
