import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var error: String?
    @State private var isRegistering = false
    
    var body: some View {
        VStack {
            LogoView()
            
            
            
            Spacer()
            
            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(
                action: {
                    AuthenticationManager.shared.login(email: email, password: password) { error in
                        if let error = error {
                            self.error = error.localizedDescription
                        }
                    }
                }
            ) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                    Text("Login")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(5)
            }
            
            Spacer()

            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)

                Button(action: {
                    self.isRegistering = true
                }) {
                    Text("Register here!")
                        .underline()
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .sheet(isPresented: $isRegistering) {
            RegisterView(isRegistering: $isRegistering)
        }
        .onAppear {
            if AuthenticationManager.shared.isLoggedIn {
                AuthenticationManager.shared.logout()
            }
        }
    }
}
