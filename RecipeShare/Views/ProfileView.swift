import SwiftUI
import Firebase
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var user: User?
    @State private var recipes: [Recipe] = []
    @State private var bookmarkCount = 0
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteWarning = false
    @State private var showDeleteConfirmation = false

    private let firestoreService = FirestoreService.shared

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading profile...")
                } else if showError {
                    Text("Failed to load profile: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VStack {
                        if let photoURL = user?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 10)
                                    .padding(.all, 5)
                                    .onTapGesture {
                                        updateProfilePhoto()
                                    }
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                                .padding(.all, 5)
                                .onTapGesture {
                                    updateProfilePhoto()
                                }
                        }

                        if let displayName = user?.displayName {
                            Text(displayName)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.all, 5)
                        }

                        if let email = user?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.all, 5)
                        }

                        Text("Owned Recipes: \(recipes.count)")
                            .padding(.all, 2)
                        Text("Bookmarks: \(bookmarkCount)")
                            .padding(.all, 2)
                    
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .onAppear(perform: loadProfile)
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showDeleteConfirmation) {
                if !recipes.isEmpty {
                    return Alert(
                        title: Text("Delete Account"),
                        message: Text("You have recipes associated with your account. Please delete them before deleting your account."),
                        dismissButton: .default(Text("OK")) {
                            showDeleteWarning = true
                        }
                    )
                } else {
                    return Alert(
                        title: Text("Are you sure?"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteAccount()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
    
    private func updateProfilePhoto() {
        /*authManager.updateProfilePhoto { error in
            if let error = error {
                self.errorMessage = "Failed to update profile photo: \(error.localizedDescription)"
                self.showError = true
            } else {
                loadProfile()
            }
        }
         */
    }

    private func loadProfile() {
        guard let currentUser = authManager.getUser() else {
            self.showError = true
            self.errorMessage = "User not authenticated"
            return
        }

        self.user = currentUser
        self.isLoading = true

        // Fetch recipes
        firestoreService.fetchRecipes(startAfter: nil, pageSize: Int.max) { result in
            switch result {
                case .success(let (recipes, _)):
                    self.recipes = recipes
                case .failure(let error):
                    self.errorMessage = "Failed to fetch owned recipes: \(error.localizedDescription)"
                    self.showError = true
            }
        }

        // Fetch bookmarks count
        firestoreService.getUserInfo(uid: currentUser.uid) { user, error in
            self.isLoading = false
            if let error = error {
                self.errorMessage = "Failed to fetch bookmarks: \(error.localizedDescription)"
                self.showError = true
            } else {
                self.bookmarkCount = user?.bookmarks.count ?? 0
            }
        }
    }

    private func deleteAccount() {
        // Check if the user has owned recipes
        if !recipes.isEmpty {
            print("not empty!")
            self.showDeleteWarning = true
        } else {
            firestoreService.deleteUserData() { error in
               if let error = error {
                   self.errorMessage = "Failed to delete user data: \(error.localizedDescription)"
                   self.showError = true
               } else {
                   self.authManager.deleteAccount { error in
                       if let error = error {
                           self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                           self.showError = true
                       }
                   }
               }
           }
        }
    }
}
