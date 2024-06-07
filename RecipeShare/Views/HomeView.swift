import SwiftUI

struct HomeView: View {
    @State private var recipes: [Recipe] = []
    @State private var selectedNavItem: NavigationItem? = nil
    @State private var isLoggedIn = true
    
    enum NavigationItem: String, CaseIterable {
        case home = "house.fill"
        case addRecipe = "plus.circle.fill"
        case profile = "person.fill"
        case bookmarks = "bookmark.fill"
        case myRecipes = "list.bullet"
    }

    func title(for item: NavigationItem) -> some View {
        HStack {
            Image(systemName: item.rawValue)
            Text(titleText(for: item))
        }
    }
    
    func titleText(for item: NavigationItem) -> String {
        switch item {
        case .home:
            return "Home"
        case .addRecipe:
            return "Add Recipe"
        case .profile:
            return "Profile"
        case .myRecipes:
            return "Your Recipes"
        case .bookmarks:
            return "Bookmarks"
        }
    }
    
    init() {
        // Fetch current user from AuthenticationManager
        if let user = AuthenticationManager.shared.getUser() {
            FirestoreService.shared.linkAuthUserToFirestore(uid: user.uid, email: user.email, displayName: user.displayName) { error in
                if let error = error {
                    print("Error linking user to Firestore: \(error.localizedDescription)")
                } else {
                    print("User successfully linked to Firestore")
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack() {
                //Image("chef")
                //    .resizable()
                //    .frame(width: 100, height: 100)
                //    .clipShape(Circle())
                
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 120)
                    .edgesIgnoringSafeArea(.top)
                    Text("RecipeShare")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
                
                NavigationView {
                    List {
                        ForEach(NavigationItem.allCases, id: \.self) { item in
                            NavigationLink(destination: self.destinationView(for: item), tag: item, selection: self.$selectedNavItem) {
                                self.title(for: item)
                            }
                        }
                        NavigationLink(destination: loginView(), label: {
                           HStack {
                               Image(systemName: "arrow.counterclockwise.circle")
                               Text("Logout")
                           }
                           .foregroundColor(Color(.systemRed))
                       })
                    }
                    .navigationTitle("Menu")
                    .navigationBarTitle("RecipeShare", displayMode: .inline)
                    .onAppear {
                        // Select Home by default
                        // self.selectedNavItem = .home
                    }
                }
            }
            //.padding()
            .edgesIgnoringSafeArea(.all)
        }
    }

    func loginView() -> some View {
        LoginView()
    }

    func destinationView(for item: NavigationItem) -> some View {
        switch item {
        case .home:
            return AnyView(
                FeedView(navigationTitle: "Your Feed")
                    .onAppear {
                        FirestoreService.shared.fetchStrategy = "all"
                    }
            )
        case .addRecipe:
            return AnyView(AddRecipeView())
        case .myRecipes:
            return AnyView(
                FeedView(navigationTitle: "Your Recipes")
                    .onAppear {
                        FirestoreService.shared.fetchStrategy = "user"
                    }
            )
        case .bookmarks:
            return AnyView(
                FeedView(navigationTitle: "Your Bookmarks")
                    .onAppear {
                        FirestoreService.shared.fetchStrategy = "bookmarked"
                    }
            )
        case .profile:
            return AnyView(
                ProfileView()
                    .onAppear {
                        FirestoreService.shared.fetchStrategy = "user"
                    }
            )
        }
    }
    
    func title(for item: NavigationItem) -> String {
        switch item {
        case .home:
            return "Home"
        case .addRecipe:
            return "Add Recipe"
        case .profile:
            return "Profile"
        case .myRecipes:
            return "Your Recipes"
        case .bookmarks:
            return "Bookmarks"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
