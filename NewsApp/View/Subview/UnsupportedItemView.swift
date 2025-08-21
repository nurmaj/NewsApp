//
//  UnsupportedItemView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 4/2/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct UnsupportedItemView: View {
    var body: some View {
        Text("not_supported_paragraph")
            .font(.callout)
            .fontWeight(.light)
            .italic()
            .foregroundColor(Color("BlackTint").opacity(0.7))
            .padding(.horizontal, 10)
            /*.padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(style: StrokeStyle(lineWidth: 1.0, dash: [5]))
                    .foregroundColor(Color("GreyTint"))
                    //.stroke(Color("GreyTint"), lineWidth: 1)
            )*/
            .padding(.bottom, 20)
    }
}

struct UnsupportedItemView_Previews: PreviewProvider {
    static var previews: some View {
        UnsupportedItemView()
            //.preferredColorScheme(.dark)
    }
}
