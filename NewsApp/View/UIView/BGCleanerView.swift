//
//  BGCleanerView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 21/10/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct BGCleanerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
       let view = UIView()
       DispatchQueue.main.async {
           view.superview?.superview?.backgroundColor = .clear
       }
       return view
   }

   func updateUIView(_ uiView: UIView, context: Context) {}
}
