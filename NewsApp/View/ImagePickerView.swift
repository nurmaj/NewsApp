//
//  ImagePickerView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 25/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CompactImagePickerView: View {
    @EnvironmentObject
    var viewModel: ImagePickerViewModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                Button(action: presentPickerWithCamera, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                        Image(systemName: "camera.fill")
                            .resizable()
                            .foregroundColor(.white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44)
                    }
                    .frame(width: 100)
                })
            }
        }
        .frame(height: 100)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
    private func presentPickerWithCamera() {
        withAnimation(.easeInOut) {
            viewModel.presentPickerSheet(.camera)
        }
    }
}
struct ImagePickerView: View {
    @EnvironmentObject
    var viewModel: ImagePickerViewModel
    private var columns = Array(repeating: GridItem(.adaptive(minimum: 100, maximum: 300), spacing: 4), count: 3)
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 4) {
                
            }
        }
    }
}
struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        CompactImagePickerView()
    }
}
