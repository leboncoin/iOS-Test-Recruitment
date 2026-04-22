import Foundation

struct Listing: Codable, Identifiable {
    let id: Int
    let categoryId: Int
    let title: String
    let description: String
    let price: Double
    let creationDate: Date
    let isUrgent: Bool
    var imagesUrl: ImagesUrl?

    struct ImagesUrl: Codable {
        var small: String?
        var thumb: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price
        case categoryId = "category_id"
        case creationDate = "creation_date"
        case isUrgent = "is_urgent"
        case imagesUrl = "images_url"
    }
}
