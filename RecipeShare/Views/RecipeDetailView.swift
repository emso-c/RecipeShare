import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var reviews: [Review] = []
    @State private var newComment: String = ""
    @State private var isAddingReview: Bool = false
    @State private var isShareSheetPresented: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    // Recipe Photo
                    if let photoURL = recipe.photoURL {
                        AsyncImage(url: photoURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                                    .clipped()
                                    .cornerRadius(10)
                                    .shadow(radius: 10)
                            } else if phase.error != nil {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                                    .clipped()
                                    .cornerRadius(10)
                                    .shadow(radius: 10)
                            } else {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                            }
                        }
                    }

                    // Recipe Name and Description
                    Text(recipe.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.vertical, 5)
                    Text(recipe.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }

                Group {
                    // Ingredients
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recipe.ingredients.indices, id: \.self) { index in
                                    Text(recipe.ingredients[index])
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }

                    // Cooking Time
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.primary)
                        Text("\(recipe.cookingTime) minutes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 10)
                }

                Group {
                    // Recipe Steps
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Steps")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        ForEach(recipe.steps.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                Text(recipe.steps[index])
                                    .font(.body)
                                    .padding(.leading, 5)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                HStack{
                    Button(action: {
                        isShareSheetPresented.toggle()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Share")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .sheet(isPresented: $isShareSheetPresented) {
                        ShareSheet(items: [shareableRecipeText()])
                    }
                    
                    Button(action: {
                        isAddingReview.toggle()
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Add Review")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .sheet(isPresented: $isAddingReview) {
                        AddReviewView(recipeID: recipe.id) { review in
                            FirestoreService.shared.addReview(review: review) { error in
                                if let error = error {
                                    print("Error adding review: \(error)")
                                } else {
                                    reviews.insert(review, at: 0)
                                }
                                isAddingReview = false
                            }
                        }
                    }
                }


                Group {
                    // Reviews
                    Text("Reviews")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.all, 5)
                
                    if reviews.isEmpty {
                        Text("No reviews yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(reviews, id: \.id) { review in
                            ReviewItemView(userName: review.userName, comment: review.comment, timestamp: review.timestamp)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarTitle("", displayMode: .inline)
        .onAppear {
            fetchReviews()
        }
    }
    
    private func shareableRecipeText() -> String {
        var text = "Check out this recipe I found on RecipeShare: \(recipe.name)\n\n"
        text += "Description: \(recipe.description)\n\n"
        text += "Ingredients:\n"
        for ingredient in recipe.ingredients {
            text += "- \(ingredient)\n"
        }
        text += "\nSteps:\n"
        for (index, step) in recipe.steps.enumerated() {
            text += "\(index + 1). \(step)\n"
        }
        text += "\nCooking Time: \(recipe.cookingTime) minutes\n"
        return text
    }
    
    private func fetchReviews() {
        FirestoreService.shared.fetchReviews(forRecipe: recipe.id) { reviews, error in
            if let reviews = reviews {
                self.reviews = reviews
            } else if let error = error {
                print("Error fetching reviews: \(error)")
            }
        }
    }
}



/*
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(
            recipe: Recipe(data:[
                "id": "1",
                "ownerId": "user123",
                "name": "Delicious Pasta",
                "description": "A flavorful pasta dish with a rich tomato sauce.",
                "photoURL": "https://www.indianhealthyrecipes.com/wp-content/uploads/2023/05/red-sauce-pasta-recipe.jpg",
                "ingredients": ["Pasta", "Tomato Sauce", "Garlic", "Olive Oil", "Basil"],
                "steps": [
                    "Boil pasta until al dente.",
                    "In a separate pan, heat olive oil and sauté minced garlic until fragrant.",
                    "Add tomato sauce and simmer for 10 minutes.",
                    "Combine cooked pasta with the sauce and toss until well coated.",
                    "Serve hot, garnished with fresh basil leaves."
                ],
                "cookingTime": 30,
                "rating": 4.5,
                "ratedBy": ["user456", "user789"],
                "createdAt": Date()
            ])!
        )
    }
}
*/
