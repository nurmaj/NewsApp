//
//  CustomDivider.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 12/3/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CustomDivider: View {
    var width: CGFloat = .infinity
    var height: CGFloat = 1
    var color: Color = Color("GreyLight")
    var opacity: Double = 1
    
    var body: some View {
        Group {
            Rectangle()
        }
        //.frame(width: width, height: height)
        .frame(maxWidth: width, maxHeight: height)
        .foregroundColor(color.opacity(opacity))
        //.opacity(opacity)
    }
}
struct CustomDivider_Previews: PreviewProvider {
    static var previews: some View {
        //CustomDivider()
        CustomDivider(width: 1, height: .infinity, color: Color.black)
    }
}
