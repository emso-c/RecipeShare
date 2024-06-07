import SwiftUI
import Firebase
import FirebaseFirestore

struct FeedView: View {
    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    var navigationTitle: String
    
    // Errors
    @State private var errorMessage = "Error"
    @State private var showError = false
    @State private var successMessage = "Success"
    @State private var showSuccess = false
    
    // fetch
    @State private var isFetchingMore = false
    @State private var lastDocument: DocumentSnapshot?
    
    // Edit
    @State private var isEditingRecipe = false
    @State private var selectedRecipe: Recipe?
    
    // view
    @State private var isViewingRecipe = false
    
    // Filter states
    @State private var isFiltering = false
    @State private var searchText = ""
    @State private var minCookingTime = 0
    @State private var maxCookingTime = 120
    @State private var selectedIngredients: [String] = []
    
    // Sort
    @State private var isAscendingOrder = true

    private let firestoreService = FirestoreService.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading recipes...")
                } else if showError {
                    Text("Failed to load recipes: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                else if recipes.isEmpty {
                    Text("No recipes found")
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                 else {
                    RefreshableScrollView(onRefresh: fetchRecipes) {
                        LazyVStack {
                            ForEach(recipes) { recipe in
                                RecipeCard(
                                    recipe: recipe,
                                    onEditTapped: {
                                        selectedRecipe = recipe
                                        isEditingRecipe = true
                                        print("tapped recipe:")
                                        print(recipe.name)
                                    },
                                    onDeleteTapped: {
                                        firestoreService.deleteRecipe(recipeID: recipe.id) { error in
                                            if let error = error {
                                                showError=true
                                                errorMessage = "Error deleting recipe: \(error.localizedDescription)"
                                            } else {
                                                showSuccess=true
                                                successMessage="Recipe deleted successfully"
                                            }
                                        }
                                    },
                                    onRateTapped: { rating in
                                        firestoreService.addRating(recipeID: recipe.id, rating: rating, userID: AuthenticationManager.shared.getUser()?.uid ?? "") { error in
                                            if let error = error {
                                                print("Error rating recipe: \(error.localizedDescription)")
                                            } else {
                                                if let index = recipes.firstIndex(of: recipe) {
                                                    recipes[index].ratedBy.append(AuthenticationManager.shared.getUser()?.uid ?? "")
                                                    recipes[index].rating = ((recipes[index].rating * Double(recipes[index].ratedBy.count - 1)) + rating) / Double(recipes[index].ratedBy.count)
                                                }
                                            }
                                        }
                                    }
                                )
                                .onAppear {
                                    selectedRecipe = recipe
                                    if recipe == recipes.last && !isLoading {
                                        print("fetch more triggered")
                                        fetchMoreRecipes()
                                    }
                                }
                                .onTapGesture {
                                    selectedRecipe = recipe
                                    isViewingRecipe = true
                                }
                            }
                            
                            if isFetchingMore {
                                ProgressView()
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(navigationTitle, displayMode: .inline)
            .navigationBarHidden(false)
            .onAppear(perform: fetchRecipes)
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showSuccess) {
                Alert(title: Text("Success"), message: Text(successMessage), dismissButton: .default(Text("OK")) {
                    fetchRecipes()
                })
            }
            .sheet(isPresented: $isEditingRecipe) {
                if let recipe = selectedRecipe {
                    EditRecipeView(recipe: recipe)
                        .onAppear {
                            print("srlected: ")
                            print(selectedRecipe!.name as Any)
                        }
                }
            }
            .sheet(isPresented: $isViewingRecipe) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe)
                        .onAppear {
                            print("srlected detail view: ")
                            print(selectedRecipe!.name as Any)
                        }
                }
            }
            .sheet(isPresented: $isFiltering) {
                FilterView(
                    isPresented: $isFiltering,
                    searchText: $searchText,
                    minCookingTime: $minCookingTime,
                    maxCookingTime: $maxCookingTime,
                    selectedIngredients: $selectedIngredients,
                    onFilterDone: { filteredRecipes in
                        recipes = filteredRecipes
                    }
                )
            }
            .navigationBarItems(trailing:
                HStack {
                    Button(action: {
                        isFiltering = true
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }

                    /*
                    Button(action: {
                        fetchRecipes()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle")
                    }
                    */

                    Button(action: {
                        if isAscendingOrder {
                            recipes.sort { $0.name < $1.name }
                        } else {
                            recipes.sort { $0.name > $1.name }
                        }
                        isAscendingOrder.toggle()
                    }) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            )
        }
    }
    
    private func fetchRecipes() {
        isLoading = true
        recipes.removeAll()
        lastDocument = nil
        firestoreService.fetchRecipes(startAfter: nil) { result in
            isLoading = false
            switch result {
            case .success(let (recipes, lastDocument)):
                self.recipes = recipes
                print("initial recipe count:")
                print(recipes.count)
                self.lastDocument = lastDocument
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func fetchMoreRecipes() {
        guard !isFetchingMore, let lastDocument = lastDocument else { return }
        isFetchingMore = true
        firestoreService.fetchRecipes(startAfter: lastDocument) { result in
            isFetchingMore = false
            switch result {
            case .success(let (moreRecipes, lastDocument)):
                self.recipes.append(contentsOf: moreRecipes)
                self.lastDocument = lastDocument
                print(recipes.count)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}
