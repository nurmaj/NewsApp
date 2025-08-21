//
//  CustomActionSheet.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 24/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CustomActionSheet: View {
    /*@EnvironmentObject
    var viewModel: AlertSheetVM*/
    @EnvironmentObject
    var stateVM: StateViewModel
    let content: SheetAlertContent?
    @State
    private var contentHeight: CGFloat = .zero
    @State
    private var showContent = false
    private var safeBottom: CGFloat {
        return safeEdges?.bottom != nil ? 40 : 20
    }
    var body: some View {
        ZStack {
            Color.black
                .opacity(0.3)
            if showContent {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        if let title = content?.title {
                            Text(title.text)
                                .font(.title2)
                            CustomDivider()
                        }/* else if let modifiedTitle = viewModel.sheetTitleType {
                            switch modifiedTitle {
                            case .imagePicker:
                                CompactImagePickerView()
                            }
                        }*/
                        if let sheetItems = content?.sheetItems {
                            ForEach(sheetItems) { item in
                                Button(action: {
                                    item.action?()
                                }, label: {
                                    Text(item.text)
                                        .font(.title3)
                                        .lineLimit(1)
                                        .foregroundColor(item.type == .cancelBtn ? Color.red : Color("BlueTint"))
                                        .frame(maxWidth: .infinity, minHeight: 60)
                                })
                                /*RoundedActionButton(text: item.text, minHeight: 60, roundedCorner: 0, textSize: Font.title3) {
                                    item.closure?(nil)
                                }*/
                                if item.id != sheetItems.last?.id {
                                    CustomDivider(color: Color.gray.opacity(0.35))//("WhiteBgColor")
                                }
                            }
                        }
                    }
                    .background(Color("WhiteBgColor").opacity(0.95))
                    .background(Color("GreyDarker"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    //.opacity(0.9)
                    /*.background(RoundedRectangle(cornerRadius: 24)
                                    .fill(Color("WhiteBgColor")))*/
                    .padding(.bottom, 10)
                    if let dismissBtn = content?.dismissBtn {
                        Button(action: dismissSheetBtnAction, label: {
                            Text(dismissBtn.text)
                                .font(.title3)
                                .lineLimit(1)
                                .foregroundColor(dismissBtn.type == .cancelBtn ? Color.red : Color("BlueTint"))
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color("WhiteBgColor").opacity(0.95))
                                .background(Color("GreyDarker"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        })
                        //.opacity(0.9)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, safeBottom)
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            withAnimation(.easeInOut) {
                self.showContent = true
            }
        }
        .ignoresSafeArea()
    }
    private func dismissSheetBtnAction() {
        withAnimation(.easeInOut) {
            self.showContent = false
            content?.dismissBtn.action?()
            //stateVM.dismissSheet()
            //self.content = nil
        }
    }
}
private struct CustomActionSheet_PreviewHolder: View {
    /*@StateObject
    var viewModel = AlertSheetVM()*/
    var body: some View {
        CustomActionSheet(content: nil)
            /*.environmentObject(viewModel)
            .onAppear {
                viewModel.presentActionSheet(contentItem: SheetAlertContent(title: nil, message: nil, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, closure: { _ in }), actionBtn: nil), sheetState: .form, sheetItems: [CustomAlertButton(text: "open_gallery", type: .defaultBtn, closure: {_ in}), CustomAlertButton(text: "remove_photo", type: .cancelBtn, closure: {_ in})])
            }*/
    }
}
struct CustomActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        CustomActionSheet_PreviewHolder()
            //.preferredColorScheme(.dark)
        /*CustomActionSheet(showSheet: .constant(true), title: nil, sheetItems: [AlertSheetItem(text: "yes_exit", type: .cancelBtn, closure: { _ in }), AlertSheetItem(text: "done", type: .defaultBtn, closure: { _ in })], content: {
            Spacer()
        })*/
    }
}
