import Foundation
import Firebase

struct Recipe: Identifiable, Equatable {
    var id: String
    var ownerId: String
    var name: String
    var description: String
    var photoURL: URL?
    var ingredients: [String]
    var steps: [String]
    var cookingTime: Int
    var rating: Double
    var ratedBy: [String]
    var createdAt: Date

    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let ownerId = data["ownerId"] as? String,
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let ingredients = data["ingredients"] as? [String],
              let steps = data["steps"] as? [String],
              let cookingTime = data["cookingTime"] as? Int,
              let createdAtTimestamp = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.description = description
        self.ingredients = ingredients
        self.steps = steps
        self.cookingTime = cookingTime
        self.rating = data["rating"] as? Double ?? 0.0
        self.ratedBy = data["ratedBy"] as? [String] ?? []
        self.createdAt = createdAtTimestamp.dateValue()

        if let photoURLString = data["photoURL"] as? String {
            self.photoURL = URL(string: photoURLString)
        } else {
            self.photoURL = nil
        }
    }
    
    static func == (left: Recipe, right: Recipe) -> Bool {
        return left.id == right.id
    }

    var dictionary: [String: Any] {
        return [
            "id": id,
            "ownerId": ownerId,
            "name": name,
            "description": description,
            "ingredients": ingredients,
            "steps": steps,
            "cookingTime": cookingTime,
            "rating": rating,
            "ratedBy": ratedBy,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

