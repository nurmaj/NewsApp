//
//  CustomAlert.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 20/10/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct CustomAlert: View {
    let content: SheetAlertContent?
    var body: some View {
        GeometryReader { geo in
            if let content = self.content {
                AlertContent(frameSize: geo.size, content: content)
            }
        }
        .onAppear {
            UITextView.appearance().backgroundColor = .clear
        }
    }
    enum ForPage {
        case menu, video
    }
    enum ViewType {
        case logout, report
    }
    enum ButtonType: String {
        case defaultBtn, cancelBtn
    }
    enum ActionState {
        case none, form, sending, failed, success
    }
}
typealias CustomAlertType = CustomAlert.ViewType
typealias AlertSheetPage = CustomAlert.ForPage
fileprivate struct AlertContent: View {
    @EnvironmentObject
    var stateVM: StateViewModel
    @State
    private var contentWidth = CGFloat.zero
    let frameSize: CGSize
    let content: SheetAlertContent
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    if stateVM.alertState == .success {
                        Text(LocalizedStringKey(stateVM.resultMsg ?? ""))
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.bottom, 10)
                            .padding(.horizontal, 15)
                    } else {
                        if let titleConf = content.title {
                            Text(titleConf.text)
                                .font(titleConf.textFont)
                                .fontWeight(titleConf.textWeight)
                                .foregroundColor(titleConf.fgColor)
                                .padding(.bottom, content.messageType != .text ? 14 : 10)
                                .padding(.horizontal, 8)
                        }
                        AlertMessageRow(content: content)
                        if stateVM.alertState == .failed && !(stateVM.resultMsg ?? "").isEmpty {
                            Text(LocalizedStringKey(stateVM.resultMsg ?? ""))
                                .font(.body)
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 4)
                                .padding(.top, 10)
                                .padding(.bottom, 2)
                        }
                    }
                    CustomDivider(width: .infinity, height: 1)
                        .padding(.top, 8)
                    HStack(spacing: 0) {
                        Button(action: dismissCustomAlert) {
                            Text(stateVM.alertState == .success ? "close" : content.dismissBtn.text)
                                .font(.body)
                                .fontWeight(content.dismissBtn.textWeight)
                                .foregroundColor(content.dismissBtn.type == .cancelBtn ? Color.red : nil)
                        }
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                        .frame(maxWidth: .infinity)
                        if let actionBtn = content.actionBtn, stateVM.alertState != .success {
                            Button(action: {
                                actionBtn.action?()
                            }) {
                                Text(actionBtn.text)
                                    .fontWeight(actionBtn.textWeight)
                                    .foregroundColor(actionBtn.type == .cancelBtn ? Color.red : nil)
                            }
                            .padding(.top, 15)
                            .padding(.bottom, 15)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .overlay(
                        content.actionBtn != nil && stateVM.alertState != .success ? CustomDivider(width: 1, height: .infinity) : nil
                    )
                }
                .frame(width: contentWidth)
                .padding(.top, 20)
                .background(Color("WhiteDarker"))
                .foregroundColor(Color("BlackTint"))
                .cornerRadius(15)
                .overlay(
                    stateVM.alertState == .sending ?
                    ZStack {
                        Color.gray.opacity(0.1)
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("GreyLight"))
                            .frame(width: 100, height: 100)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                            .frame(width: 32, height: 24)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        : nil
                )
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: frameSize.height)
            .onAppear() {
                self.contentWidth = frameSize.width - 70 > 200 ? frameSize.width - 70 : frameSize.width - 20
            }
        }
        .background(
                    Color("GreyDarker")
                        .opacity(0.7)
                        .ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .all)
        .onTapGesture {
            if content.messageType == .editable {
                withAnimation {
                    UIApplication.shared.closeKeyboard()
                }
            }
        }
    }
    private func dismissCustomAlert() {
        content.dismissBtn.action?()
        stateVM.dismissAlert()
    }
}
fileprivate struct AlertMessageRow: View {
    @EnvironmentObject
    var stateVM: StateViewModel
    let content: SheetAlertContent
    var body: some View {
        if let messageConf = self.content.message {
            if content.messageType == .editable {
                Text(stateVM.editTextVal.isEmpty ? messageConf.text : LocalizedStringKey(stateVM.editTextVal))
                    .font(messageConf.textFont)
                    .fontWeight(messageConf.textWeight)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .foregroundColor(messageConf.fgColor)
                    .opacity(stateVM.editTextVal.isEmpty || stateVM.alertState == .sending ? 1 : 0)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color("BlackTint").opacity(0.2), lineWidth: 1)
                            .padding(.horizontal, 15)
                    )
                    .overlay(
                        TextEditor(text: $stateVM.editTextVal)
                            .font(messageConf.textFont)
                            .foregroundColor(Color("BlackTint"))
                            .padding(.top, 2)
                            .padding(.horizontal, 15)
                            .opacity(stateVM.alertState == .sending ? 0 : 1)
                        , alignment: .leading
                    )
            } else if content.messageType == .label {
                HStack(spacing: 6) {
                    Image(systemName: messageConf.sysIcName)
                        .imageScale(.large)
                    Text(messageConf.text)
                        .font(messageConf.textFont)
                        .fontWeight(messageConf.textWeight)
                        .lineLimit(nil)
                }
                .foregroundColor(messageConf.fgColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                .padding(.horizontal, 15)
            } else {
                Text(messageConf.text)
                    .font(messageConf.textFont)
                    .fontWeight(messageConf.textWeight)
                    .foregroundColor(messageConf.fgColor)
                    .lineLimit(nil)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 15)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
    }
}

struct SheetAlertContent {
    var title: AlertText?
    var message: AlertText?
    var messageType: MessageType = .text
    var dismissBtn: CustomAlertButton
    var actionBtn: CustomAlertButton?
    var sheetItems: [CustomAlertButton]?
    var forPage: AlertSheetPage?
    
    enum MessageType {
        case text, editable, label
    }
}
struct AlertText {
    let text: LocalizedStringKey
    var textFont: Font = .title3
    var textWeight: Font.Weight = .semibold
    var sysIcName: String = ""
    var fgColor: Color = Color("BlackTint")
}
struct CustomAlertButton: Identifiable {
    let id = UUID().uuidString
    let text: LocalizedStringKey
    var textWeight: Font.Weight = .regular
    let type: CustomAlert.ButtonType
    let action: (() -> Void)?
}
private struct CustomAlert_PreviewHolder: View {
    var body: some View {
        CustomAlert(content: SheetAlertContent(title: AlertText(text: "confirm_vote_select", textFont: .body, textWeight: .regular), message: AlertText(text: "Random text", textWeight: .regular, sysIcName: "checkmark.circle.fill", fgColor: Color.accentColor), messageType: .label, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: nil), actionBtn: CustomAlertButton(text: "vote", textWeight: .semibold, type: .cancelBtn, action: nil)))
    }
}
struct CustomAlert_Previews: PreviewProvider {
    static var previews: some View {
        CustomAlert_PreviewHolder()
            .preferredColorScheme(.dark)
    }
}
