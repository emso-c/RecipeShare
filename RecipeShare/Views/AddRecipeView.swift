import SwiftUI
import Firebase
import PhotosUI
import FirebaseFirestore

struct AddRecipeView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var ingredients = ""
    @State private var steps = ""
    @State private var cookingTime = ""
    @State private var image: UIImage? = nil
    @State private var isShowingImagePicker = false
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoading = false
    private let firestoreService = FirestoreService.shared
    private let currentUser = AuthenticationManager.shared.getUser()
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Ingredients (comma separated)", text: $ingredients)
                    TextField("Steps (dot separated)", text: $steps)
                    TextField("Cooking Time (minutes)", text: $cookingTime)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    VStack(alignment: .center) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                //.frame(height: 200)
                                .onTapGesture {
                                    isShowingImagePicker = true
                                }
                        } else {
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                Text("Select Photo")
                            }
                        }
                    }
                }
                
                Button(action: addRecipe) {
                    Text("Add Recipe")
                }
                .disabled(isLoading)
            }
            .navigationBarTitle("Add Recipe")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $image)
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(title: Text("Success"), message: Text("Recipe added successfully!"), dismissButton: .default(Text("OK")) {
                    self.presentationMode.wrappedValue.dismiss()
                    clearFields()
                })
            }
        }
    }
    
    private func addRecipe() {
        guard let currentUser = self.currentUser else {
            errorMessage = "User not authenticated."
            showError = true
            return
        }

        let uid = currentUser.uid
        let id = UUID().uuidString
        guard let cookingTimeInt = Int(cookingTime) else {
            errorMessage = "Cooking time must be a number."
            showError = true
            return
        }

        let ingredientList = ingredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let stepList = steps.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let recipeData: [String: Any] = [
            "id": id,
            "ownerId": uid,
            "name": name,
            "description": description,
            "ingredients": ingredientList,
            "steps": stepList,
            "cookingTime": cookingTimeInt,
            "rating": 0.0,
            "ratedBy": [],
            "createdAt": Timestamp(date: Date())
        ]

        guard let recipe = Recipe(data: recipeData) else {
            errorMessage = "Failed to create recipe. Please check your inputs."
            showError = true
            return
        }

        isLoading = true

        let photoData = image?.jpegData(compressionQuality: 0.8)
        
        firestoreService.createRecipe(recipe: recipe, photoData: photoData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error adding recipe: \(error.localizedDescription)"
                showError = true
            } else {
                showSuccessAlert = true
            }
        }
    }

    private func clearFields() {
        name = ""
        description = ""
        ingredients = ""
        steps = ""
        cookingTime = ""
        image = nil
    }
}
