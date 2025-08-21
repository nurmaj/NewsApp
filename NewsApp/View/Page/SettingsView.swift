//
//  SettingsView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 5/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    let onCloseTap: () -> Void
    @StateObject
    var viewModel = SettingsViewModel()
    @State
    private var presentDetail: MenuDetailKey?
    var body: some View {
        //Group {
        if presentDetail == .settingsTab {
            SettingsDetailView(viewModel: viewModel, onCloseTap: dismissDetailSettings)
                .transition(.move(edge: .trailing))
                .zIndex(2)
        } else if presentDetail == .about {
            AboutView(onCloseTap: dismissDetailSettings)
                .transition(.move(edge: .trailing))
                .zIndex(2)
                .analyticsScreen(name: "About Page", class: String(describing: AboutView.self))
        } else {
            VStack(spacing: .zero) {
                TopBarView(leadingBtn: {
                    BackButtonView(closeIconOnly: true, onCloseTap: onCloseTap)
                }, logo: false, trailingBtn: {}, bgColor: Color("GreyPurpleBlack"))
                ScrollView {
                    VStack(alignment: .leading, spacing: .zero) {
                        SettingsGroupCaption(caption: "data")
                        SettingsToggleView(label: "data_saver", isOn: $viewModel.dataSaver)
                        SettingsInfoText(text: "data_saver_info")
                        // MARK: Tab Customisation
                        SettingsGroupCaption(caption: "tabs", topPadding: 30)
                        Button(action: {
                            self.presentDetailForSettings(which: .settingsTab)
                        }) {
                            HStack(spacing: .zero) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("launch_tab")
                                        .font(.body)
                                    Text(viewModel.launchTabItem?.name ?? "—")
                                        .font(.callout)
                                        .foregroundColor(Color("GreyDarker"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .imageScale(.medium)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 70)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color("WhiteBgColor")))
                        }
                        
                        Button(action: {
                            self.presentDetailForSettings(which: .about)
                        }) {
                            HStack(spacing: 10) {
                                Text("about_app")
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .imageScale(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color("WhiteBgColor")))
                        }
                        .padding(.top, 16)
                    }
                    .onChange(of: viewModel.dataSaver, perform: { newState in
                        viewModel.changeDataSaverState(newState)
                    })
                    .foregroundColor(Color("BlackTint"))
                    .padding(.vertical, 20)
                    .padding(.horizontal, 18)
                }
            }
            .analyticsScreen(name: "Settings", class: String(describing: SettingsView.self))
        }
        //}
    }
    private func presentDetailForSettings(which: MenuDetailKey) {
        withAnimation {
            self.presentDetail = which
        }
    }
    private func dismissDetailSettings() {
        withAnimation {
            self.presentDetail = nil
        }
    }
}

struct SettingsDetailView: View {
    @StateObject
    var viewModel: SettingsViewModel
    let onCloseTap: () -> Void
    var body: some View {
        VStack {
            TopBarView(leadingBtn: {
                BackButtonView(onCloseTap: onCloseTap)
            }, logo: false, title: "tabs", trailingBtn: {}, bgColor: Color("GreyPurpleBlack"))
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    SettingsGroupCaption(caption: "launch_tab", topPadding: 30)
                    VStack(spacing: .zero) {
                        ForEach(viewModel.launchableTabItems) { tabItem in
                            SettingsCheckMarkText(isChecked: .constant(tabItem.key == viewModel.launchTabItem?.key), text: tabItem.name, showSeparator: tabItem.key != viewModel.launchableTabItems.last?.key, onCheckMarkTap: {  onSettingLaunchTab(item: tabItem) })
                        }
                        if viewModel.launchableTabItems.isEmpty {
                            Text("no_tab_is_launchable")
                                .padding(.vertical, 20)
                        }
                    }
                    .foregroundColor(Color("BlackTint"))
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color("WhiteBgColor")))
                    .padding(.horizontal, 14)
                }
            }
        }
        .frame(maxHeight: .infinity)
        //.edgesIgnoringSafeArea(.all)
        .background(Color("GreyPurpleBlack").ignoresSafeArea())
        .overlay(viewModel.showMessage ? MsgBannerView(message: $viewModel.messageText, iconName: .constant(""), show: $viewModel.showMessage) : nil, alignment: .bottom)
        .analyticsScreen(name: "Launch Tab Selection Configure", class: String(describing: SettingsDetailView.self))
    }
    private func onSettingLaunchTab(item: TabItem) {
        if item.key != viewModel.launchTabItem?.key {
            withAnimation {
                viewModel.setLaunchTabItem(item)
                viewModel.showSettingsMsgBanner(msg: "launch_tab_set_msg")
            }
        }
    }
}

// View Modifiers
fileprivate struct SettingsGroupCaption: View {
    let caption: String
    var topPadding: CGFloat = 8
    var body: some View {
        Text(LocalizedStringKey(caption))
            .font(.callout)
            .textCase(.uppercase)
            .foregroundColor(Color("GreyDarker"))
            .padding(.top, topPadding)
            .padding(.bottom, 6)
            .padding(.leading, 14)
    }
}
fileprivate struct SettingsToggleView: View {
    let label: String
    @Binding
    var isOn: Bool
    var body: some View {
        Toggle(LocalizedStringKey(label), isOn: $isOn)
            .padding(.horizontal, 14)
            .frame(height: 60)
            .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color("WhiteBgColor")))
    }
}
fileprivate struct SettingsInfoText: View {
    let text: String
    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.callout)
            .foregroundColor(Color("GreyDarker"))
            .padding(.top, 6)
            .padding(.leading, 14)
    }
}
fileprivate struct SettingsCheckMarkText: View {
    @Binding
    var isChecked: Bool
    let text: String
    let showSeparator: Bool
    let onCheckMarkTap: () -> Void
    var body: some View {
        Button(action: onCheckMarkTap) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay( isChecked ?
                              Image(systemName: "checkmark")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.blue)
                                    .frame(width: 14, height: 14) : nil
                    )
                Text(LocalizedStringKey(text))
                    .font(.body)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 18)
            .padding(.trailing, 14)
            .overlay( showSeparator ?
                      CustomDivider()
                        .padding(.leading, 28): nil
                , alignment: .bottom)
            .padding(.leading, 14)
        }
    }
}
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        //SettingsView(onCloseTap: {})
        //SettingsCheckMarkText(isChecked: .constant(true), text: "Test")
        SettingsDetailView(viewModel: SettingsViewModel(), onCloseTap: {})
    }
}
