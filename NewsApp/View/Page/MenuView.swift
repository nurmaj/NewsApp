//
//  MenuView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct MenuView: View {
    @StateObject
    var viewModel = MenuViewModel()
    @EnvironmentObject
    var stateVM: StateViewModel
    //var alertSheetVM: AlertSheetVM
    let onLoginPresent: (LoginViewItem) -> Void
    /*@StateObject
    var alertVM = CustomAlertViewModel()*/
    /*init() {
        UINavigationBar.appearance().backgroundColor = .clear
    }*/
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(viewModel: viewModel, onLoginPresent: onLoginPresent)
                    .padding(.bottom, 20)
                if viewModel.accountEditMode {
                    MenuAccountEdit(viewModel: viewModel)
                        .padding(.horizontal, 18)
                } else {
                    VStack(spacing: 0) {
                        MenuContent(viewModel: viewModel)
                    }
                    //.padding(.bottom, 6)
                    .background(RoundedRectangle(cornerRadius: 18)
                                    .fill(Color("WhiteBgColor")))
                    .padding(.horizontal, 18)
                        
                }
            }
            .onAppear {
                viewModel.checkAccountStatus()
            }
            .onChange(of: viewModel.alertState, perform: { state in
                if state == .form {
                    if viewModel.alertType == .logout {
                        if let user = viewModel.user {
                            stateVM.presentAlert(contentItem: SheetAlertContent(title: AlertText(text: "logout_confirm \(user.email)", textFont: .body, textWeight: .regular), message: nil, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: dismissMenuAlert), actionBtn: CustomAlertButton(text: "yes_exit", textWeight: .semibold, type: .cancelBtn, action: viewModel.logoutUser)))
                        }
                    } else if viewModel.alertType == .report {
                        stateVM.presentAlert(contentItem: SheetAlertContent(title: AlertText(text: "report"), message: AlertText(text: "enter_problem_message", textFont: .body, textWeight: .regular), messageType: .editable, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: dismissMenuAlert), actionBtn: CustomAlertButton(text: "send", textWeight: .semibold, type: .cancelBtn, action: {
                            self.stateVM.sendReport(page: "menu", issueItem: nil)
                        })))
                    } else {

                    }
                } else {
                    if state == .none && stateVM.alertPresented() {
                        dismissMenuAlert()
                    } else {
                        stateVM.setAlertState(state)
                    }
                }
            })
            .onChange(of: viewModel.accountEditMode) { editMode in
                if !editMode {
                    viewModel.cancelImageRemoteSave()
                    viewModel.showMsgBanner = false
                }
            }
            .onChange(of: viewModel.accountUpdatingState) { state in
                if state != .inited {
                    if viewModel.saveAccountInfo {
                        viewModel.saveAccountInfo = false
                    }
                    if state == .failed {
                        viewModel.showResultMsg(msg: viewModel.resultMsg ?? "cannot_update_info")
                    } else if state == .processing {
                        withAnimation {
                            UIApplication.shared.closeKeyboard()
                        }
                    }
                }
            }
            .onChange(of: viewModel.accountDeleteUrlState) { state in
                if state == .failed {
                    withAnimation {
                        viewModel.showResultMsg(msg: viewModel.resultMsg ?? "delete_account_url_err_msg")
                    }
                } else if let accountDeleteUrl = viewModel.accountDeleteUrl, state == .success {
                    self.viewModel.webViewModalURL = accountDeleteUrl
                    self.viewModel.activeCoverItem = .webView
                }
            }
        }
        .onDisappear {
            if viewModel.accountEditMode {
                viewModel.accountEditMode = false
            }
        }
        .overlay(
            viewModel.showMsgBanner ? MsgBannerView(message: .constant(viewModel.resultMsg ?? ""), iconName: $viewModel.resultMsgIcon, show: $viewModel.showMsgBanner) : nil
            , alignment: .bottomLeading
        )
        .overlay(
            viewModel.accountUpdatingState == .processing || viewModel.accountDeleteUrlState == .processing ?
            ZStack {
                Color.gray.opacity(0.1)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("GreyLight"))
                    .frame(width: 100, height: 100)
                CircleProgressBar(widthHeight: 32)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                : nil
        )
        .fullScreenCover(item: $viewModel.activeCoverItem) { which in
            switch which {
            case .webView:
                if let webUrl = viewModel.webViewModalURL {
                    WebView(urlItem: WebViewItem(url: webUrl) { _ in false }, onDismiss: {
                        self.viewModel.activeCoverItem = nil
                    })
                    .analyticsScreen(name: webUrl.absoluteString, class: String(describing: MenuView.self))
                }
            case .itemViewer:
                if let avatarItem = viewModel.user?.avatar {
                    SingleItemViewer(imageItem: avatarItem)
                        .preferredColorScheme(.dark)
                        .analyticsScreen(name: avatarItem.thumb.absoluteString, class: String(describing: MenuView.self))
                }
            case .menuDetail:
                if let menuItem = viewModel.menuItemForDetail {
                    MenuDetailView(menuItem: menuItem, onCloseTap: {
                        self.viewModel.activeCoverItem = nil
                        self.viewModel.menuItemForDetail = nil
                    })
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("GreyPurpleBlack").ignoresSafeArea())
    }
    func dismissMenuAlert() {
        self.viewModel.alertState = .none
        self.viewModel.alertType = nil
        self.stateVM.dismissAlert()
    }
}
fileprivate struct HeaderView: View {
    @StateObject
    var viewModel: MenuViewModel
    @EnvironmentObject
    var stateVM: StateViewModel
    let onLoginPresent: (LoginViewItem) -> Void
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                Spacer()
                if !viewModel.accountEditMode {
                    Text("account")
                        .font(.title3)
                        .foregroundColor(Color("BlackTint"))
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 6)
            .overlay( viewModel.user != nil ?
                HStack {
                    if viewModel.accountEditMode {
                        Button(action: {
                            withAnimation(.linear) {
                                viewModel.accountEditMode = false
                            }
                        }, label: {
                            Text("cancel")
                                .font(.body)
                                .foregroundColor(Color("BlueLink"))
                                .padding(.vertical, 6)
                                .padding(.top, 4)
                        })
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                    }
                    Spacer()
                    Button(action: {
                        if viewModel.accountEditMode {
                            viewModel.saveAccountInfo = true
                        } else {
                            withAnimation(.linear) {
                                viewModel.accountEditMode = true
                            }
                        }
                    }, label: {
                        Text(viewModel.accountEditMode ? "done" : "edit_abr")
                            .font(.body)
                            .fontWeight(viewModel.accountEditMode ? .semibold : .regular)
                            .foregroundColor(Color("BlueLink"))
                            .padding(.vertical, 6)
                            .padding(.top, 4)
                    })
                    .padding(.leading, 4)
                    .padding(.trailing, 10)
                }: nil, alignment: .top
            )
            if let account = viewModel.user {
                ZStack {
                    if let newAvatar = viewModel.newAvatarImage {
                        Image(uiImage: newAvatar)
                            .resizable()
                            .frame(width: 72, height: 72)
                            .aspectRatio(contentMode: .fit)
                            .padding(.vertical, 10)
                            .clipShape(Circle())
                    } else if let avatarItem = account.avatar {
                        Button(action: {
                            viewModel.activeCoverItem = .itemViewer
                        }, label: {
                            AsyncImage(url: avatarItem.thumb, placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                            }, failure: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                            })
                                .frame(width: 72, height: 72)
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(Color("GreyTint"))
                                .padding(.vertical, 10)
                                .clipShape(Circle())
                        })
                    } else {
                        getProfileIcon(sysName: "person.circle.fill")
                    }
                }
                .overlay(viewModel.accountEditMode && viewModel.avatarRequestState == .processing ? avatarActionProgress : nil)
                if !viewModel.accountEditMode {
                    if let fullName = account.getFullName() {
                        Text("\(fullName)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                    }
                    HStack(spacing: 4) {
                        Text("\(account.email)")
                            .font(.body)
                        if !account.name.isEmpty {
                            Text("•")
                            Text("@\(account.name)")
                                .font(.body)
                        }
                    }
                    .foregroundColor(Color("GreyDark"))
                    HStack(spacing: 4) {
                        Text("balance_id \(String(account.id))")
                            .font(.callout)
                        Text("•")
                        Text("balance_sum \(account.balance)")
                            .font(.callout)
                    }
                    .padding(.top, 2)
                    .foregroundColor(Color("GreyDark"))
                } else {
                    getImageUploadBtn(hasAcc: account.avatar != nil)
                }
            } else {
                getProfileIcon(sysName: "person.circle")
                Button(action: {
                    onLoginPresent(LoginViewItem(onSignIn: { _ in }, onDismiss: {
                        viewModel.checkAccountStatus()
                    }))
                }) {
                    Text("sign_in")
                        .foregroundColor(Color("BlackTint"))
                        .textCase(.uppercase)
                        .font(.callout)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("AlternateAccent"))
                        )
                }
                Button(action: {
                    if let helpUrl = URL(string: API.SharedPage().page(.helpCenter, section: .whyAccount)),
                       UIApplication.shared.canOpenURL(helpUrl) {
                        UIApplication.shared.open(helpUrl)
                    }
                }) {
                    Text("why_sign_in")
                        .font(.callout)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                }
                .foregroundColor(Color("GreyDark"))
            }
        }
        .onChange(of: viewModel.avatarRequestState) { state in
            if state == .failed {
                if viewModel.avatarActionType == .add {
                    viewModel.newAvatarImage = nil
                    viewModel.showResultMsg(msg: "cannot_upload_new_avatar")
                } else if viewModel.avatarActionType == .delete {
                    viewModel.showResultMsg(msg: "cannot_remove_avatar")
                }
                viewModel.avatarActionType = nil
            } else if state == .success {
                viewModel.avatarActionType = nil
                if viewModel.newAvatarImage != nil {
                    viewModel.newAvatarImage = nil
                }
            }
            if (state == .failed || state == .success) && stateVM.sheetPresented() {
                stateVM.dismissSheet()
            }
        }
        .onChange(of: stateVM.sheetItemAction) { actionType in
            if actionType == .delete {
                stateVM.dismissSheet()
                stateVM.presentSheet(contentItem: SheetAlertContent(dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: dismissActionSheet), sheetItems: [CustomAlertButton(text: "remove", type: .cancelBtn, action: removeRemoteImageAction)]))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    func getProfileIcon(sysName: String) -> some View {
        Image(systemName: sysName)
            .resizable()
            .frame(width: 64, height: 64)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color("GreyTint"))
            .padding(.vertical, 10)
    }
    @ViewBuilder
    func getImageUploadBtn(hasAcc: Bool) -> some View {
        Button(action: {
            if viewModel.avatarRequestState == .processing {
                if viewModel.avatarActionType == .add {
                    stateVM.presentSheet(contentItem: SheetAlertContent(dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: nil), sheetItems: [CustomAlertButton(text: "cancel_upload", type: .cancelBtn, action: cancelImageSaveToRemote)]))
                }
            } else {
                presentPickerFromMenu()
            }
        }, label: {
            HStack {
                if hasAcc {
                    Text("change_photo")
                } else {
                    Image("add_a_photo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    Text("upload_photo")
                }
            }
            .foregroundColor(Color("BlueTint"))
        })
    }
    func presentPickerFromMenu() {
        stateVM.presentPicker(onResult: { pickedImage in
            self.stateVM.dismissPicker()
            self.viewModel.saveImageToRemote(pickedImage)
        })
    }
    func dismissActionSheet() {
        stateVM.dismissSheetAction()
        stateVM.dismissPicker()
    }
    func cancelImageSaveToRemote() {
        viewModel.cancelImageRemoteSave()
        stateVM.dismissSheet()
    }
    func removeRemoteImageAction() {
        self.dismissActionSheet()
        self.viewModel.removeRemoteImage()
    }
    var avatarActionProgress: some View {
        CircleProgressBar(cancellable: viewModel.avatarActionType == .add, onCancel: {
            viewModel.cancelImageRemoteSave()
        })
        .frame(width: 44, height: 44)
    }
}
struct MenuContent: View {
    @StateObject
    var viewModel: MenuViewModel
    var body: some View {
        ForEach(viewModel.menuItems) { menuItem in
            Group {
                Button(action: {
                    if let shareUrlStr = menuItem.urlStr {
                        self.viewModel.webViewModalURL = URL(string: shareUrlStr)
                        self.viewModel.activeCoverItem = .webView
                    } else if let action = menuItem.action {
                        action()
                    } else if let _ = menuItem.detailKey {
                        self.viewModel.menuItemForDetail = menuItem
                        self.viewModel.activeCoverItem = .menuDetail
                    }
                }, label: {
                    MenuItemView(menuItem: menuItem)
                })
            }
            .overlay(menuItem.id != viewModel.menuItems.last?.id ? CustomDivider().padding(.horizontal, 18) : nil, alignment: .bottom)
        }
        .foregroundColor(Color("BlackTint"))
    }
    private struct MenuItemView: View {
        var menuItem: MenuItem
        var body: some View {
            HStack(spacing: 10) {
                if let systemIc = menuItem.systemIcName {
                    Image(systemName: systemIc)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                } else if let customIc = menuItem.customIcName {
                    Image(customIc)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color("BlackTint"))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
                Text(LocalizedStringKey(menuItem.name))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
    }
}
private struct MenuAccountEdit: View {
    @StateObject
    var viewModel: MenuViewModel
    @StateObject
    private var editAccount = EditableAccountFieldsVM()
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 1) {
                CleanTextField(viewModel: CleanTextFieldVM(), textVal: $editAccount.firstName, hint: "first_name", fieldHeight: 54, leadingSpace: 10)
                CleanTextField(viewModel: CleanTextFieldVM(), textVal: $editAccount.lastName, hint: "last_name", fieldHeight: 54, leadingSpace: 10)
            }
            .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color("WhiteBgColor")))
            .overlay(CustomDivider()
                        .padding(.leading, 20))
            .padding(.bottom, 25)
            
            CleanTextField(viewModel: CleanTextFieldVM(), textVal: $editAccount.userName, hint: "user_name", fieldHeight: 54, leadingSpace: 10)
                .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color("WhiteBgColor")))
                .overlay(Text("@")
                            .font(.callout)
                            .foregroundColor(Color("GreyDarker"))
                            .padding(.leading, 4)
                         , alignment: .leading)
            Text("user_name_why")
                .font(.system(size: 14))
                .foregroundColor(Color("GreyDarker"))
                .padding(.top, 4)
                .padding(.bottom, 8)
                .padding(.leading, 20)
            Text("user_name_rule")
                .font(.system(size: 14))
                .foregroundColor(Color("GreyDarker"))
                .padding(.bottom, 25)
                .padding(.leading, 20)
            Spacer()
            VStack(alignment: .leading, spacing: .zero) {
                Button(action: showAccountDeleteRequest) {
                    Text("remove_account")
                        .font(.body)
                        .foregroundColor(Color("GreyFont"))
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                }
                CustomDivider()
                Button(action: {
                    viewModel.showAlert(which: .logout)
                }, label: {
                    Text("logout")
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(Color("ErrorTint"))
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                })
            }
            .padding(.leading, 20)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Color("WhiteBgColor")))
        }
        .onChange(of: viewModel.saveAccountInfo) { save in
            if save {
                viewModel.saveUserInfoToRemote(newUsername: editAccount.userName, newFirstname: editAccount.firstName, newLastname: editAccount.lastName)
            }
        }
        .onAppear {
            self.setEditAcc()
        }
    }
    private func showAccountDeleteRequest() {
        withAnimation {
            viewModel.retrieveAccountDeleteUrl()
        }
    }
    private func setEditAcc() {
        if let user = viewModel.user {
            editAccount.firstName = user.firstName ?? ""
            editAccount.lastName = user.lastName ?? ""
            editAccount.userName = user.name
        }
    }
    private class EditableAccountFieldsVM: ObservableObject {
        @Published
        var firstName: String = ""
        @Published
        var lastName: String = ""
        @Published
        var userName: String = ""
    }
}
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(onLoginPresent: { _ in })
    }
}
