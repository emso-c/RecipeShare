//
//  RefreshableScrollView.swift
//  RecipeShare
//
//  Created by Patron on 28.05.2024.
//

import SwiftUI

struct RefreshableScrollView<Content: View>: View {
    var content: Content
    var onRefresh: () -> Void
    
    init(onRefresh: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        List {
            content
                .listRowSeparator(.hidden)
        }
        .refreshable {
            onRefresh()
        }
        .background(Color(.systemGray6))
    }
}
