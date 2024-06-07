import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager = AuthenticationManager.shared

    var body: some View {
        VStack {
            if authManager.isLoading {
                LoadingView()
            } else {
                if authManager.isLoggedIn {
                    HomeView()
                } else {
                    LoginView()
                }
            }
        }
        .onAppear {
            authManager.checkAuthentication()
        }
    }
}
