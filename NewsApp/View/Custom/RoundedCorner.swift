//
//  RoundedCorner.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 8/9/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
