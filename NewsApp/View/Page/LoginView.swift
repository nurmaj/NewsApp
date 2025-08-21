//
//  LoginView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 8/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @StateObject
    var loginVM = LoginViewModel()
    @Binding
    var loginItem: LoginViewItem?
    @State
    private var showMsgBanner = false
    private var safeSize: CGFloat {
        return (safeEdges?.top ?? 0) + (safeEdges?.bottom ?? 0)
    }
    private var screenSize: CGRect {
        return getRect()
    }
    @State
    private var contentHeight: CGFloat = .zero
    // TODO: Implement focus state on iOS 15
    /*@FocusState
    private var focusedField: FocusedField?*/
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(spacing: 14) {
                        Image("AppLogo")
                            .renderingMode(.template)
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.bottom, 20)
                        LoginTextField(textVal: $loginVM.userName, hint: "email_or_login", keyboardType: .emailAddress)
                        LoginTextField(textVal: $loginVM.userPwd, hint: "password", secureField: true, contentType: .newPassword)
                        HStack(spacing: 0) {
                            Spacer()
                            Button(action: {
                                loginVM.openModal(which: .restore)
                            }) {
                                Text("forget_password")
                                    .font(.callout)
                                    .padding(.top, 4)
                                    .padding(.bottom, 8)
                                    .foregroundColor(Color("BlueTint"))
                            }
                        }
                        .padding(.bottom, 10)
                        if !loginVM.errorMsg.isEmpty {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                Text(LocalizedStringKey(loginVM.errorMsg))
                                    .font(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                                .foregroundColor(Color("ErrorTint"))
                                .animation(.linear)
                        } else if loginVM.signInState == .success {
                            successText
                        }
                        Button(action: onSignInTap) {
                            Text("sign_in")
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(Color("PrimaryColor"))
                                .cornerRadius(6)
                        }
                        .disabled(loginVM.fieldsEmpty() || loginVM.signInState == .success)
                        .opacity(loginVM.fieldsEmpty() || loginVM.signInState == .success ? 0.6 : 1)
                        .overlay(loginVM.signInState == .processing ?
                                CircleProgressBar(widthHeight: 24)
                                    .padding(.trailing, 12) : nil
                            , alignment: .trailing)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                .frame(minHeight: proxy.size.height - (safeSize == 0 ? 10 : safeSize), alignment: .center)
            }
            .frame(height: contentHeight)
            .background(Color("WhiteBlackBg"))
            .onTapGesture {
                if loginVM.keyboardOpened {
                    withAnimation {
                        UIApplication.shared.closeKeyboard()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                // Write code for keyboard opened.
                withAnimation {
                    loginVM.keyboardOpened = true
                }
            }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                // Write code for keyboard closed.
                withAnimation {
                    loginVM.keyboardOpened = false
                }
            }
            .onAppear {
                if let _ = loginItem?.bannerMsg {
                    showMsgBanner.toggle()
                }
                if contentHeight < proxy.size.height {
                    contentHeight = proxy.size.height
                }
            }
            .onChange(of: showMsgBanner) { show in
                if !show {
                    loginItem?.bannerMsg = nil
                }
            }
            .overlay(
                BottomActionView(text: "no_account", btnText: "sign_up_dot") { loginVM.openModal(which: .signUp) }
                    .padding(.bottom, (safeEdges?.bottom ?? 4) + 6)
                , alignment: .bottom
            )
            .overlay(showMsgBanner && !(loginItem?.bannerMsg ?? "").isEmpty ? MsgBannerView(message: .constant(loginItem?.bannerMsg ?? ""), iconName: .constant(""), show: $showMsgBanner, appearDuration: 4)
                        .padding(.bottom, safeEdges?.bottom ?? 10): nil, alignment: .bottom)
            .analyticsScreen(name: "Login Page", class: String(describing: LoginView.self))
        }
        .overlay(
            Button(action: dismissModal) {
                Image(systemName: "xmark")
                    .imageScale(.large)
                    .foregroundColor(Color("BlackTint"))
                    .padding(.top, (safeEdges?.top ?? 4) + 6)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            , alignment: .topLeading
        )
        .fullScreenCover(isPresented: $loginVM.modalPresented) {
            if loginVM.authType == .restore {
                RestorePwdView(viewModel: loginVM)
            } else if loginVM.authType == .signUp {
                SignUpView(viewModel: loginVM)
            } else {
                EmptyView()
            }
        }
        .overlay(loginVM.signInState == .success ?
                 Color.clear.ignoresSafeArea()
                    .contentShape(Rectangle()) : nil)
    }
    var successText: some View {
        Text(LocalizedStringKey(!loginVM.successMsg.isEmpty ? loginVM.successMsg : "signin_success_msg"))
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(Color("DarkAccentColor"))
            .padding(.bottom, 16)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.linear) {
                        self.dismissModal()
                    }
                }
            }
    }
    private func onSignInTap() {
        if loginVM.signInState == .processing {
            return
        }
        withAnimation {
            UIApplication.shared.closeKeyboard()
        }
        loginVM.makeAuthRequest { user in
            loginItem?.onSignIn(user)
        }
    }
    private func dismissModal() {
        withAnimation {
            self.loginItem?.onDismiss()
            self.loginItem = nil
        }
    }
    enum FocusedField: Hashable {
        case username
        case password
    }
}
fileprivate struct RestorePwdView: View {
    @StateObject
    var viewModel: LoginViewModel
    @State
    private var contentHeight: CGFloat = .zero
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("restore_password")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 40)
                    if viewModel.signInState == .success {
                        AttributedTextView(text: String(format: NSLocalizedString("restore_success_msg", comment: ""), viewModel.userEmail))
                    } else {
                        Text("restore_password_info")
                            .font(.callout)
                            .foregroundColor(Color("GreyDarker"))
                            .padding(.bottom, 10)
                            .offset(y: -8)
                        LoginTextField(textVal: $viewModel.userEmail, hint: "enter_email", keyboardType: .emailAddress)
                            .padding(.bottom, 10)
                        if !viewModel.errorMsg.isEmpty {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                Text(LocalizedStringKey(viewModel.errorMsg))
                                    .font(.callout)
                            }
                                .foregroundColor(Color("ErrorTint"))
                                .animation(.linear)
                        }
                        Button(action: onRestoreTap) {
                            Text("reset")
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(Color("PrimaryColor"))
                                .cornerRadius(6)
                        }
                        .disabled(viewModel.fieldsEmpty())
                        .opacity(viewModel.fieldsEmpty() ? 0.6 : 1)
                        .overlay(viewModel.signInState == .processing ?
                                CircleProgressBar(widthHeight: 24)
                                    .padding(.trailing, 12) : nil
                            , alignment: .trailing)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                .frame(minHeight: proxy.size.height - (safeEdges?.top ?? 16), alignment: .center)
            }
            .onAppear {
                if contentHeight < proxy.size.height {
                    contentHeight = proxy.size.height
                }
                viewModel.cleanTypeFields(which: .restore)
            }
            .frame(height: contentHeight)
            .overlay(
                BottomActionView(btnText: "back_to_login") { viewModel.closeModal() }, alignment: .bottom
            )
            .onTapGesture {
                if viewModel.keyboardOpened {
                    withAnimation {
                        UIApplication.shared.closeKeyboard()
                    }
                }
            }
            .analyticsScreen(name: "Restore Password Page", class: String(describing: RestorePwdView.self))
        }
    }
    private func onRestoreTap() {
        if viewModel.signInState == .processing {
            return
        }
        withAnimation {
            UIApplication.shared.closeKeyboard()
        }
        viewModel.makeAuthRequest { _ in }
    }
}
fileprivate struct SignUpView: View {
    @StateObject
    var viewModel: LoginViewModel
    @State
    private var contentHeight: CGFloat = .zero
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("sign_up")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 40)
                        .padding(.bottom, 16)
                    if viewModel.signInState == .success {
                        AttributedTextView(text: String(format: NSLocalizedString("signup_success_msg", comment: ""), viewModel.userEmail))
                    } else {
                        LoginTextField(textVal: $viewModel.userEmail, hint: "enter_email", keyboardType: .emailAddress)
                            .padding(.bottom, 10)
                        LoginTextField(textVal: $viewModel.userPwd, hint: "enter_password", secureField: true, contentType: .newPassword)
                        Text("password_rule")
                            .font(.callout)
                            .foregroundColor(Color("GreyDarker"))
                            .offset(y: -8)
                        LoginTextField(textVal: $viewModel.userPwdConfirm, hint: "confirm_password", secureField: true)
                            .padding(.bottom, 10)
                        if !viewModel.errorMsg.isEmpty {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                Text(LocalizedStringKey(viewModel.errorMsg))
                                    .font(.callout)
                            }
                                .foregroundColor(Color("ErrorTint"))
                                .animation(.linear)
                        }
                        Button(action: onSignUpTap) {
                            Text("make_sign_up")
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(Color("PrimaryColor"))
                                .cornerRadius(6)
                        }
                        .disabled(viewModel.fieldsEmpty())
                        .opacity(viewModel.fieldsEmpty() ? 0.6 : 1)
                        .overlay(viewModel.signInState == .processing ?
                                CircleProgressBar(widthHeight: 24)
                                    .padding(.trailing, 12) : nil
                            , alignment: .trailing)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                .frame(minHeight: proxy.size.height - (safeEdges?.top ?? 16), alignment: .center)
            }
            .onAppear {
                if contentHeight < proxy.size.height {
                    contentHeight = proxy.size.height
                }
                viewModel.cleanTypeFields(which: .signUp)
            }
            .frame(height: contentHeight)
            .overlay(
                BottomActionView(btnText: "back_to_login") { viewModel.closeModal() }, alignment: .bottom
            )
            .onTapGesture {
                if viewModel.keyboardOpened {
                    withAnimation {
                        UIApplication.shared.closeKeyboard()
                    }
                }
            }
            .analyticsScreen(name: "SignUp Page", class: String(describing: SignUpView.self))
        }
    }
    private func onSignUpTap() {
        if viewModel.signInState == .processing {
            return
        }
        withAnimation {
            UIApplication.shared.closeKeyboard()
        }
        viewModel.makeAuthRequest {_ in}
    }
}
private struct BottomActionView: View {
    var text: String?
    var btnText: String
    var action: () -> ()
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            CustomDivider(color: Color("GreyWhite"))
            if let plainText = text {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(plainText))
                        //.font(.callout)
                        .font(.system(size: 15))
                        .foregroundColor(Color("GreyDark"))
                    actionBtn
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            } else {
                actionBtn
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
            }
        }
    }
    private var actionBtn: some View {
        Button(action: { action() }) {
            Text(LocalizedStringKey(btnText))
                .font(.system(size: 15))
                .fontWeight(.semibold)
                .foregroundColor(Color("BlueLight"))
        }
    }
}
struct LoginTextField: View {
    @Binding
    var textVal: String
    var hint: String
    var secureField = false
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType?
    @State
    private var showPwd = false
    var body: some View {
        Text(LocalizedStringKey(textVal.isEmpty ? hint : textVal))
            .font(.body)
            .padding(.top, 14)
            .padding(.bottom, 13)
            .padding(.horizontal, 10)
            .foregroundColor(Color("GreyDarker"))
            .opacity(textVal.isEmpty ? 1 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color("GreyDarker").opacity(0.8), lineWidth: 1)
            )
            .overlay(
                getTextField()
                    .font(.body)
                    .foregroundColor(Color("BlackTint"))
                    .padding(.horizontal, 10)
                , alignment: .leading
            )
            .overlay(secureField ? securePwdSwitch : nil, alignment: .trailing)
    }
    @ViewBuilder
    func getTextField() -> some View {
        if secureField && !showPwd {
            SecureField("", text: $textVal)
                .textContentType(contentType ?? .password)
                .disableAutocorrection(true)
        } else {
            TextField("", text: $textVal)
                .textContentType(contentType)
                .keyboardType(keyboardType ?? .default)
                .autocapitalization(disableAutoFeatures() ? .none : .sentences)
                .disableAutocorrection(disableAutoFeatures() ? true : false)
        }
    }
    var securePwdSwitch: some View {
        Button(action: {
            self.showPwd.toggle()
        }) {
            Image(systemName: showPwd ? "eye" : "eye.slash")
                .foregroundColor(Color(showPwd ? "BlueTint" : "GreyDarker"))
        }
        .padding(.vertical, 4)
        .padding(.leading, 4)
        .padding(.trailing, 10)
    }
    func disableAutoFeatures() -> Bool {
        return keyboardType == .emailAddress || secureField
    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(loginItem: .constant(LoginViewItem(onSignIn: {_ in}, onDismiss: {})))
    }
}
