//
//  BgShapeView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 14/7/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct BgShapeView: View {
    var color = Color("WhiteBlackBg")
    var body: some View {
        Rectangle()
            .fill(color)
    }
}

struct BgShapeView_Previews: PreviewProvider {
    static var previews: some View {
        BgShapeView()
    }
}
