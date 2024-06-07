import SwiftUI

struct EditRecipeView: View {
    let recipe: Recipe
    @State private var name: String
    @State private var description: String
    @State private var ingredients: String
    @State private var steps: String
    @State private var cookingTime: String
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoading = false
    private let firestoreService = FirestoreService.shared
    @State private var errorMessage = ""
    @State private var showError = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _name = State(initialValue: recipe.name)
        _description = State(initialValue: recipe.description)
        _ingredients = State(initialValue: recipe.ingredients.joined(separator: ". "))
        _steps = State(initialValue: recipe.steps.joined(separator: ". "))
        _cookingTime = State(initialValue: "\(recipe.cookingTime)")
    }

    var body: some View {
        Form {
            Section(header: Text("Recipe Details")) {
                TextField("Name", text: $name)
                TextField("Description", text: $description)
                TextField("Ingredients (comma separated)", text: $ingredients)
                TextField("Steps (dot separated)", text: $steps)
                TextField("Cooking Time (minutes)", text: $cookingTime)
                    .keyboardType(.numberPad)
            }

            Button(action: updateRecipe) {
                Text("Update Recipe")
            }
            .disabled(isLoading)
        }
        // .navigationBarTitle("Edit Recipe")
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func updateRecipe() {
        let ingredientList = ingredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let stepList = steps.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let cookingTimeInt = Int(cookingTime) else {
            errorMessage = "Cooking time must be a number."
            showError = true
            return
        }

        let newData: [String: Any] = [
            "name": name,
            "description": description,
            "ingredients": ingredientList,
            "steps": stepList,
            "cookingTime": cookingTimeInt
        ]

        isLoading = true
        firestoreService.updateRecipe(recipeID: recipe.id, newData: newData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error updating recipe: \(error.localizedDescription)"
                showError = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
