import Foundation

struct Review {
    let id: String
    let recipeID: String
    let userID: String
    let userName: String
    let comment: String
    let timestamp: Date

    var dictionary: [String: Any] {
        return [
            "id": id,
            "recipeID": recipeID,
            "userID": userID,
            "userName": userName,
            "comment": comment,
            "timestamp": timestamp
        ]
    }
}
