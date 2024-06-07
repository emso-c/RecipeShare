import SwiftUI

struct RatingPromptView: View {
    @Binding var isPresented: Bool
    @Binding var rating: Double
    let onRateTapped: (Double) -> Void
    
    var body: some View {
        VStack {
            Text("Rate Recipe")
                .font(.title)
                .padding()
            
            Spacer()
            
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Button(action: { rating = Double(index) }) {
                        Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Button("Rate") {
                onRateTapped(rating)
                isPresented = false
            }
            .padding()
            
            Spacer()
        }
    }
}


struct RatingPromptView_Previews: PreviewProvider {
    static var previews: some View {
        RatingPromptView(isPresented: .constant(true), rating: .constant(0), onRateTapped: { _ in })
    }
}
