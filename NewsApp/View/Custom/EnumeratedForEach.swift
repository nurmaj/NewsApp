//
//  EnumeratedForEach.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 16/11/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct EnumeratedForEach<ItemType, ContentView: View>: View {
    let data: [ItemType]
    let content: (Int, ItemType) -> ContentView

    init(_ data: [ItemType], @ViewBuilder content: @escaping (Int, ItemType) -> ContentView) {
        self.data = data
        self.content = content
    }

    var body: some View {
        ForEach(Array(zip(data.indices, data)), id: \.0) { idx, item in
            content(idx, item)
        }
    }
}

struct EnumeratedForEach_Previews: PreviewProvider {
    static var previews: some View {
        Text("adasdasdasdasd asda sda dasdasd adasd")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24)
            .overlay(Text("1. "), alignment: .leading)
            .padding(.leading, 10)
    }
}

