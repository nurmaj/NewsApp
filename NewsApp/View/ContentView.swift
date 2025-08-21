//
//  ContentView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 16/12/20.
//

import SwiftUI
import FirebaseAnalytics
struct ContentView: View {
    init() {
        UITabBar.appearance().isHidden = true
    }
    var body: some View {
        CustomTabView()
            .navigationBarHidden(true)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
