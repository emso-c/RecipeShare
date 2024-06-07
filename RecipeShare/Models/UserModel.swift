import Foundation

struct User {
    var uid: String
    var email: String?
    var displayName: String?
    var photoURL: URL?
}

struct FirestoreUser {
    let uid: String
    let bookmarks: [String]
}
