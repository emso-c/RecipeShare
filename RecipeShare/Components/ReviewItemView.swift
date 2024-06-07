import SwiftUI

struct ReviewItemView: View {
    var userName: String
    var comment: String
    var timestamp: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(userName)
                .font(.headline)
            Text(comment)
                .font(.body)
                .foregroundColor(.secondary)
            Text("\(timestamp, formatter: DateFormatter.shortDate)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct ExampleReviewItemView: View {
    var body: some View {
        ReviewItemView(userName: "John Doe", comment: "Great recipe!", timestamp: Date())
            .padding()
    }
}

struct ReviewItemView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
