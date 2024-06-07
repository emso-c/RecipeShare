import Foundation
import Firebase

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    private init() {}
    
    @Published var isLoggedIn = false
    @Published var isLoading = false
    
    func getUser() -> User? {
        if let currentUser = Auth.auth().currentUser {
            return User(uid: currentUser.uid,
                        email: currentUser.email,
                        displayName: currentUser.displayName,
                        photoURL: currentUser.photoURL)
        } else {
            return nil
        }
    }
    
    func checkAuthentication() {
        isLoading = true
        Auth.auth().addStateDidChangeListener { auth, user in
            self.isLoading = false
            if let _ = user {
                self.isLoggedIn = true
            } else {
                self.isLoggedIn = false
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            self.isLoading = false
            if let error = error {
                completion(error)
            } else {
                self.isLoggedIn = true
                completion(nil)
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func register(email: String, password: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            self.isLoading = false
            if let error = error {
                completion(error)
            } else {
                self.isLoggedIn = true
                completion(nil)
            }
        }
    }
    
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "No user logged in", code: 401, userInfo: nil))
            return
        }
        
        isLoading = true
        user.delete { error in
            self.isLoading = false
            if let error = error {
                completion(error)
            } else {
                self.isLoggedIn = false
                completion(nil)
            }
        }
    }
}
