import Foundation
import Firebase
import FirebaseStorage

class FirestoreService {
    static let shared = FirestoreService()
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    var fetchStrategy: String = "all"
    
    private init() {}

    // MARK: - Authentication Linking

    func linkAuthUserToFirestore(uid: String, email: String?, displayName: String?, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(uid)
        var userData: [String: Any] = [:]
        if let email = email {
            userData["email"] = email
        }
        if let displayName = displayName {
            userData["displayName"] = displayName
        }
        
        userRef.setData(userData, merge: true) { error in
            completion(error)
        }
    }

    // MARK: - CRUD Operations for Firestore User

    func getUserInfo(uid: String, completion: @escaping (FirestoreUser?, Error?) -> Void) {
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
            } else if let snapshot = snapshot, snapshot.exists {
                if let data = snapshot.data(), let bookmarks = data["bookmarks"] as? [String] {
                    let user = FirestoreUser(uid: uid, bookmarks: bookmarks)
                    completion(user, nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func deleteUserData(completion: @escaping (Error?) -> Void) {
        guard let currentUser = AuthenticationManager.shared.getUser() else {
            completion(NSError(domain: "User not authenticated", code: 401, userInfo: nil))
            return
        }
        let userRef = db.collection("users").document(currentUser.uid)
        userRef.delete { error in
            if let error = error {
                completion(error)
            } else {
                // User data deleted successfully
                completion(nil)
            }
        }
    }

    func updateUser(uid: String, bookmarks: [String], completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(uid)
        let data: [String: Any] = ["bookmarks": bookmarks]

        userRef.setData(data, merge: true) { error in
            completion(error)
        }
    }
    
    func addBookmark(recipeID: String, userID: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData([
            "bookmarks": FieldValue.arrayUnion([recipeID])
        ]) { error in
            completion(error)
        }
    }
    
    func removeBookmark(recipeID: String, userID: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData([
            "bookmarks": FieldValue.arrayRemove([recipeID])
        ]) { error in
            completion(error)
        }
    }

    // MARK: - CRUD Operations for Recipe
    
    func createRecipe(recipe: Recipe, photoData: Data?, completion: @escaping (Error?) -> Void) {
        var recipeData = recipe.dictionary
        if let photoData = photoData {
            let storageRef = Storage.storage().reference().child("recipePhotos/\(recipe.id).jpg")
            storageRef.putData(photoData, metadata: nil) { metadata, error in
                if let error = error {
                    completion(error)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    recipeData["photoURL"] = url?.absoluteString ?? ""
                    self.db.collection("recipes").document(recipe.id).setData(recipeData, completion: completion)
                }
            }
        } else {
            db.collection("recipes").document(recipe.id).setData(recipeData, completion: completion)
        }
    }

    func getRecipe(recipeID: String, completion: @escaping (Recipe?, Error?) -> Void) {
        let recipeRef = self.db.collection("recipes").document(recipeID)

        recipeRef.getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
            } else if let snapshot = snapshot, snapshot.exists {
                if let data = snapshot.data() {
                    // Parse recipe
                    let recipe = Recipe(data: data)
                    completion(recipe, nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                completion(nil, nil)
            }
        }
    }

    // MARK: - Fetch Recipes with Strategy Pattern
    
    private func fetchAllRecipes(startAfter: DocumentSnapshot?, pageSize: Int = 5, completion: @escaping (Result<([Recipe], DocumentSnapshot?), Error>) -> Void) {
        var query: Query = db.collection("recipes").order(by: "createdAt", descending: true).limit(to: pageSize)
        if let lastDocument = startAfter {
            query = query.start(afterDocument: lastDocument)
        }
            
        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let recipes = snapshot.documents.compactMap { document in
                    return Recipe(data: document.data())
                }
                let lastDocument = snapshot.documents.last
                completion(.success((recipes, lastDocument)))
            }
        }
    }
    
    private func fetchBookmarkedRecipes(startAfter: DocumentSnapshot?, pageSize: Int = 5, completion: @escaping (Result<([Recipe], DocumentSnapshot?), Error>) -> Void) {
        guard let currentUser = AuthenticationManager.shared.getUser() else {
            completion(.failure(NSError(domain: "User not authenticated", code: 401, userInfo: nil)))
            return
        }

        getUserInfo(uid: currentUser.uid) { user, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = user {
                let recipeIDs = user.bookmarks
                if (recipeIDs.isEmpty) {
                    completion(.success(([], nil)))
                    return
                }

                let query = self.db.collection("recipes").whereField(FieldPath.documentID(), in: recipeIDs)
                
                var finalQuery: Query = query.limit(to: pageSize)
                if let lastDocument = startAfter {
                    finalQuery = finalQuery.start(afterDocument: lastDocument)
                }

                finalQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let snapshot = snapshot {
                        let recipes = snapshot.documents.compactMap { document in
                            return Recipe(data: document.data())
                        }
                        let lastDocument = snapshot.documents.last
                        completion(.success((recipes, lastDocument)))
                    }
                }
            }
        }
    }
    
    private func fetchUserRecipes(startAfter: DocumentSnapshot?, pageSize: Int = 5, completion: @escaping (Result<([Recipe], DocumentSnapshot?), Error>) -> Void) {
        guard let currentUser = AuthenticationManager.shared.getUser() else {
            completion(.failure(NSError(domain: "User not authenticated", code: 401, userInfo: nil)))
            return
        }

        let query = self.db.collection("recipes").whereField("ownerId", isEqualTo: currentUser.uid)
        
        var finalQuery: Query = query.limit(to: pageSize)
        if let lastDocument = startAfter {
            finalQuery = finalQuery.start(afterDocument: lastDocument)
        }

        finalQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let recipes = snapshot.documents.compactMap { document in
                    return Recipe(data: document.data())
                }
                let lastDocument = snapshot.documents.last
                completion(.success((recipes, lastDocument)))
            }
        }
    }

    public func fetchRecipes(startAfter: DocumentSnapshot?, pageSize: Int = 5, completion: @escaping (Result<([Recipe], DocumentSnapshot?), Error>) -> Void) {
        switch fetchStrategy {
            case "all":
                fetchAllRecipes(startAfter: startAfter, pageSize: pageSize, completion: completion)
            case "bookmarked":
                fetchBookmarkedRecipes(startAfter: startAfter, pageSize: pageSize, completion: completion)
            case "user":
                fetchUserRecipes(startAfter: startAfter, pageSize: pageSize, completion: completion)
            default:
                completion(.failure(NSError(domain: "Invalid fetch strategy", code: 400, userInfo: nil)))
        }
    }

    func updateRecipe(recipeID: String, newData: [String: Any], completion: @escaping (Error?) -> Void) {
        let recipeRef = db.collection("recipes").document(recipeID)

        recipeRef.updateData(newData) { error in
            completion(error)
        }
    }

    func deleteRecipe(recipeID: String, completion: @escaping (Error?) -> Void) {
        let recipeRef = db.collection("recipes").document(recipeID)

        recipeRef.getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = snapshot?.data(),
                  let photoURLString = data["photoURL"] as? String,
                  let _ = URL(string: photoURLString) else {
                recipeRef.delete { deleteError in
                    completion(deleteError)
                }
                return
            }
            
            let photoStorageRef = self.storage.reference(forURL: photoURLString)
            photoStorageRef.delete { storageError in
                if let storageError = storageError {
                    completion(storageError)
                } else {
                    recipeRef.delete { deleteError in
                        completion(deleteError)
                    }
                }
            }
        }
    }
    
    func addRating(recipeID: String, rating: Double, userID: String, completion: @escaping (Error?) -> Void) {
        let recipeRef = db.collection("recipes").document(recipeID)

        recipeRef.getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }

            guard let data = snapshot?.data(),
                  var currentRating = data["rating"] as? Double,
                  var ratedBy = data["ratedBy"] as? [String] else {
                completion(nil)
                return
            }

            if !ratedBy.contains(userID) {
                ratedBy.append(userID)
                currentRating = ((currentRating * Double(ratedBy.count - 1)) + rating) / Double(ratedBy.count)

                let newData: [String: Any] = [
                    "rating": currentRating,
                    "ratedBy": ratedBy
                ]

                recipeRef.updateData(newData) { updateError in
                    completion(updateError)
                }
            } else {
                completion(nil) // User has already rated
            }
        }
    }
    
    // MARK: Reviews
    
    func addReview(review: Review, completion: @escaping (Error?) -> Void) {
       let reviewData = review.dictionary
       db.collection("reviews").document(review.id).setData(reviewData, completion: completion)
    }
    
    func fetchReviews(forRecipe recipeID: String, completion: @escaping ([Review]?, Error?) -> Void) {
        db.collection("reviews")
           .whereField("recipeID", isEqualTo: recipeID)
           .order(by: "timestamp", descending: true)
           .getDocuments { snapshot, error in
               if let error = error {
                   completion(nil, error)
               } else {
                   let reviews = snapshot?.documents.compactMap { doc -> Review? in
                       let data = doc.data()
                       guard let id = data["id"] as? String,
                             let recipeID = data["recipeID"] as? String,
                             let userID = data["userID"] as? String,
                             let userName = data["userName"] as? String,
                             let comment = data["comment"] as? String,
                             let timestamp = data["timestamp"] as? Timestamp else {
                           return nil
                       }
                       return Review(id: id, recipeID: recipeID, userID: userID, userName: userName, comment: comment, timestamp: timestamp.dateValue())
                   }
                   completion(reviews, nil)
               }
           }
   }
}
