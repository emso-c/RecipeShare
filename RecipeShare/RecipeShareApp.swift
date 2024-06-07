//
//  RecipeShareApp.swift
//  RecipeShare
//
//  Created by Patron on 15.05.2024.
//

import SwiftUI
import Firebase

@main
struct RecipeShareApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
