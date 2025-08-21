//
//  MenuDetailView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct MenuDetailView: View {
    /*@StateObject
    var detailVM: MenuDetailViewModel*/
    let menuItem: MenuItem
    let onCloseTap: () -> Void
    //@Environment(\.presentationMode) private var presentation
    var body: some View {
        ZStack {
            if menuItem.detailKey == .settings {
                SettingsView(onCloseTap: onCloseTap)
            } else {
                VStack(spacing: .zero) {
                    TopBarView(leadingBtn: {
                        BackButtonView(backText: "menu", closeIconOnly: true, onCloseTap: onCloseTap)
                    }, logo: false, trailingBtn: {}, bgColor: Color("GreyPurpleBlack"))
                    ScrollView {
                        NotificationConfView()
                    }
                }
            }
        }
        .background(Color("GreyPurpleBlack").ignoresSafeArea())
    }
}
fileprivate struct NotificationConfView: View {
    @StateObject
    var viewModel = NotificationConfViewModel()
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("news")
                .font(.callout)
                .textCase(.uppercase)
                .foregroundColor(Color("GreyDarker"))
                .padding(.top, 8)
                .padding(.bottom, 6)
                .padding(.leading, 14)
            Toggle("main_notification_conf_message", isOn: $viewModel.mainNotificationState)
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .foregroundColor(Color("BlackTint"))
                .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color("WhiteBgColor")))
        }
        .onChange(of: viewModel.mainNotificationState, perform: { newState in
            viewModel.changeMainNotificationState(newState)
        })
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .analyticsScreen(name: "Notification Configure Page", class: String(describing: NotificationConfView.self))
    }
}
fileprivate class NotificationConfViewModel: ObservableObject {
    @Published
    var mainNotificationState = Preference.bool(.mainNotification, defaultIfNil: true)
    func changeMainNotificationState(_ newState: Bool) {
        Preference.set(newState, key: .mainNotification)
        if newState {
            FCMService.shared.subscribeToTopic(DefaultAppConfig.MAIN_PUSH_NOT_TOPIC)
        } else {
            FCMService.shared.unsubscribeFromTopic(DefaultAppConfig.MAIN_PUSH_NOT_TOPIC)
        }
    }
}
struct MenuDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDetailView(menuItem: MenuItem(name: "settings", systemIcName: "", customIcName: nil, detailKey: .notification), onCloseTap: {})
    }
}
