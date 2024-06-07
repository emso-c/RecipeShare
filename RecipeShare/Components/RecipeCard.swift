import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    let onEditTapped: () -> Void
    let onDeleteTapped: () -> Void
    let onRateTapped: (Double) -> Void
    
    private let currentUser = AuthenticationManager.shared.getUser()!
    @State private var rating: Double = 0
    @State private var isRatingPromptPresented = false
    @State private var isBookmarked: Bool = false
    private let firestoreService = FirestoreService.shared

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(recipe.createdAt, formatter: DateFormatter.shortDate)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 3)
        
            ZStack(alignment: .topTrailing) {
                if let photoURL = recipe.photoURL {
                    AsyncImage(url: photoURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 300, height: 200, alignment: .center)
                                .clipped()
                        } else if phase.error != nil {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 300, height: 200, alignment: .center)
                                .clipped()
                        } else {
                            ProgressView()
                                .frame(width: 300, height: 200)
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 300, height: 200, alignment: .center)
                        .clipped()
                }
                
                Button(action: { }) {
                    Image(systemName: isBookmarked ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 35, height: 35)
                        )
                }
                .onTapGesture {
                    toggleBookmark()
                }
            }

            // Recipe name
            Text(recipe.name)
                .font(.headline)
                .padding(.top, 10)
            
            // Average rating
            if recipe.rating > 0 {
                HStack {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(recipe.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .shadow(radius: 2)
                    }

                    Text("(\(String(format: "%.1f", recipe.rating)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 5)
            } else {
                Text("No ratings yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Ingredients
            Text("Ingredients: \(recipe.ingredients.joined(separator: ","))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Cooking time
            Text("Cooking Time: \(recipe.cookingTime) minutes")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if recipe.ownerId == currentUser.uid {
                HStack {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.white)
                            Text("Edit")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(5)
                    }
                    .onTapGesture {
                        onEditTapped()
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.white)
                            Text("Delete")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(5)
                    }
                    .onTapGesture {
                        onDeleteTapped()
                    }
                }
                .padding(.top, 10)
            } else {
                if !recipe.ratedBy.contains(currentUser.uid) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.white)
                            Text("Rate Recipe")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(5)
                    }
                    .onTapGesture {
                        isRatingPromptPresented.toggle()
                    }
                    .padding(.top, 10)
                    .sheet(isPresented: $isRatingPromptPresented) {
                        RatingPromptView(isPresented: $isRatingPromptPresented, rating: $rating, onRateTapped: { newRating in
                            onRateTapped(newRating)
                            rating = newRating
                        })
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .onAppear {
            fetchBookmarkStatus()
        }
    }
    
    private func fetchBookmarkStatus() {
        firestoreService.getUserInfo(uid: currentUser.uid) { user, error in
            if let user = user {
                isBookmarked = user.bookmarks.contains(recipe.id)
            }
        }
    }
    
    private func toggleBookmark() {
        if isBookmarked {
            firestoreService.removeBookmark(recipeID: recipe.id, userID: currentUser.uid) { error in
                if error == nil {
                    isBookmarked = false
                }
            }
        } else {
            firestoreService.addBookmark(recipeID: recipe.id, userID: currentUser.uid) { error in
                if error == nil {
                    isBookmarked = true
                }
            }
        }
    }
}
