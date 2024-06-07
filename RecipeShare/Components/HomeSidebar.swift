import SwiftUI

struct SidebarMenu: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                // Toggle menu open/close state
                withAnimation {
                    isMenuOpen.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding()
            }
            
            Spacer()
            
            // Profile picture
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .padding(.top, 20)
                .padding(.horizontal, 20)
            
            // Profile button
            Button(action: {
                // TODO Navigate to profile page
            }) {
                Text("Profile")
                    .foregroundColor(.black)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }
            
            // Bookmarks
            Button(action: {
                // TODO Navigate to bookmarks page
            }) {
                Text("Bookmarks")
                    .foregroundColor(.black)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }
            
            // Logout (logout action)
            Button(action: {
                AuthenticationManager.shared.logout()
            }) {
                Text("Logout")
                    .foregroundColor(.black)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .frame(width: 200)
        .background(Color(.systemGray6))
    }
}
