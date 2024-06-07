import SwiftUI

struct AddReviewView: View {
    let recipeID: String
    var onAddReview: (Review) -> Void
    @State private var comment: String = ""
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Review")) {
                    TextField("Your comment", text: $comment)
                }
                
                Button(action: {
                    let user = AuthenticationManager.shared.getUser()!
                    let review = Review(
                        id: UUID().uuidString,
                        recipeID: recipeID,
                        userID: user.uid,
                        userName: user.displayName ?? "Anonymous",
                        comment: comment,
                        timestamp: Date()
                    )
                    onAddReview(review)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Submit")
                }
            }
            .navigationBarTitle("New Review", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

