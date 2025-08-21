//
//  AboutView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 5/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    //@Environment(\.presentationMode) private var presentation
    let onCloseTap: () -> Void
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: .zero) {
                TopBarView(leadingBtn: {
                    BackButtonView(onCloseTap: onCloseTap)
                }, logo: false, title: "about_app", trailingBtn: {})
                ScrollView {
                    VStack {
                        Spacer()
                        Image("AppLogo")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color("PrimaryColor"))
                            .frame(width: 200)
                        Spacer()
                        VStack(spacing: 0) {
                            HStack {
                                Text("app_version_name \(Bundle.main.appVersionLong)")
                                Text("app_version_num \(Bundle.main.appBuild)")
                            }
                            .foregroundColor(Color("GreyTint"))
                            .padding(.vertical)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .overlay(CustomDivider(color: Color("GreyWhite")), alignment: .bottom)
                            Button(action: {
                                if let developerUrl = URL(string: API.Endpoint.appStoreDeveloperUrl), UIApplication.shared.canOpenURL(developerUrl) {
                                    UIApplication.shared.open(developerUrl)
                                }
                            }, label: {
                                Text("other_apps")
                                    .padding(.vertical)
                                    .padding(.horizontal, 8)
                                    .lineLimit(1)
                                    .foregroundColor(Color("BlueLight"))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            })
                            .overlay(CustomDivider(color: Color("GreyLight")).padding(.horizontal, 18), alignment: .bottom)
                            Text("copyright \(Util().currentYear)")
                                .padding(.top, 16)
                                .foregroundColor(Color("GreyTint"))
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .background(Color("WhiteBgColor").edgesIgnoringSafeArea([.top, .bottom]))
            }
            .frame(maxHeight: .infinity)
            /*.overlay(
                TopBarView(leadingBtn: {
                    BackButtonView(onCloseTap: onCloseTap)
                }, logo: false, title: "about_app", trailingBtn: {})
                , alignment: .top
            )*/
            //.edgesIgnoringSafeArea(.all)
        }
        /*.navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: { presentation.wrappedValue.dismiss() }) {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
            }
            .accentColor(Color("GreyTint"))
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("about_app")
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(Color("BlackTint"))
            }
        }*/
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(onCloseTap: {})
            .preferredColorScheme(.dark)
    }
}
