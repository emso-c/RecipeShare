import SwiftUI

struct RegisterView: View {
    @Binding var isRegistering: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var error: String?
    
    var body: some View {
        VStack {
                        
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .gray, radius: 1, x: 1, y: 1)
                .padding()
            
            
            InputField(placeholder: "Email", text: $email)
                .padding(.bottom, 10)
            
            InputField(placeholder: "Password", text: $password, isSecure: true)
                .padding(.bottom, 10)
            
            InputField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                .padding(.bottom, 20)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(
                action: {
                    if password == confirmPassword {
                        AuthenticationManager.shared.register(email: email, password: password) { error in
                            if let error = error {
                                self.error = error.localizedDescription
                            } else {
                                self.isRegistering = false
                            }
                        }
                    } else {
                        self.error = "Passwords do not match"
                    }
                }
            ) {
                HStack {
                    Image(systemName: "person.badge.plus.fill")
                        .foregroundColor(.white)
                    Text("Register")
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
        }
        .padding()
    }
}
