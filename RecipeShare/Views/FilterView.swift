import SwiftUI

struct FilterView: View {
    @Binding var isPresented: Bool
    @Binding var searchText: String
    @Binding var minCookingTime: Int
    @Binding var maxCookingTime: Int
    @Binding var selectedIngredients: [String]
    var onFilterDone: ([Recipe]) -> Void
    
    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    @State private var errorMessage = "Error"
    @State private var showError = false
    
    private let firestoreService = FirestoreService.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search by name", text: $searchText)
                }
                
                Section(header: Text("Cooking Time")) {
                    Stepper(value: $minCookingTime, in: 0...maxCookingTime, label: {
                        Text("Min: \(minCookingTime) minutes")
                    })
                    Stepper(value: $maxCookingTime, in: minCookingTime...120, label: {
                        Text("Max: \(maxCookingTime) minutes")
                    })
                }
                
                Section(header: Text("Ingredients")) {
                    ForEach(uniqueIngredients, id: \.self) { ingredient in
                        Toggle(ingredient, isOn: Binding(
                            get: { selectedIngredients.contains(ingredient) },
                            set: { isSelected in
                                if isSelected {
                                    selectedIngredients.append(ingredient)
                                } else {
                                    selectedIngredients.removeAll(where: { $0 == ingredient })
                                }
                            })
                        )
                    }
                }
                
                Section {
                    Button("Clear Filters") {
                        clearFilters()
                    }
                }
            }
            .navigationBarTitle("Filter")
            .navigationBarItems(trailing:
                Button(action: {
                    isPresented = false
                    onFilterDone(filteredRecipes)
                }, label: {
                    Text("Done")
                })
            )
            .onAppear {
                fetchRecipes()
                clearFilters()
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func fetchRecipes() {
        isLoading = true
        firestoreService.fetchRecipes(startAfter: nil, pageSize: 9999) { result in
            isLoading = false
            switch result {
            case .success(let (recipes, _)):
                self.recipes = recipes
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func clearFilters() {
        searchText = ""
        minCookingTime = 0
        maxCookingTime = 120
        selectedIngredients.removeAll()
    }
    
    private var filteredRecipes: [Recipe] {
        var filteredRecipes = recipes

        // Filter based on search text
        if !searchText.isEmpty {
            filteredRecipes = filteredRecipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Filter based on cooking time range
        filteredRecipes = filteredRecipes.filter { $0.cookingTime >= minCookingTime && $0.cookingTime <= maxCookingTime }

        // Filter based on selected ingredients
        if !selectedIngredients.isEmpty {
            filteredRecipes = filteredRecipes.filter { recipe in
                selectedIngredients.allSatisfy { recipe.ingredients.contains($0) }
            }
        }

        return filteredRecipes
    }
    
    private var uniqueIngredients: [String] {
        Set(recipes.flatMap { $0.ingredients }).sorted()
    }
}
