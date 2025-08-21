//
//  CleanTextField.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 23/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CleanTextField: View {
    @StateObject
    var viewModel: CleanTextFieldVM
    @Binding
    var textVal: String
    var hint: String
    var secureField = false
    var fieldHeight: CGFloat = .zero
    var leadingSpace: CGFloat = .zero
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType?
    var onSubmit: () -> () = {}
    var submitLabelType: TextFieldSubmitLabelType = .none
    @State
    private var showPwd = false
    var body: some View {
        Text(LocalizedStringKey(textVal.isEmpty ? hint : textVal))
            .font(.body)
            .padding(.top, 14)
            .padding(.bottom, 13)
            .padding(.horizontal, 10)
            .padding(.leading, leadingSpace)
            .foregroundColor(Color("GreyDarker"))
            .opacity(textVal.isEmpty ? 1 : 0)
            .frame(maxWidth: .infinity, minHeight: fieldHeight, alignment: .leading)
            .overlay(
                getTextField()
                    .font(.body)
                    .foregroundColor(Color("BlackTint"))
                    .padding(.horizontal, 10)
                    .padding(.leading, leadingSpace)
                , alignment: .leading
            )
            .overlay(secureField ? securePwdSwitch : nil, alignment: .trailing)
    }
    @ViewBuilder
    func getTextField() -> some View {
        if secureField && !showPwd {
            secureFieldView
        } else {
            if viewModel.focusable {
                FocusedTextField(focused: $viewModel.fieldFocused, text: $textVal, onSubmit: onSubmit, content: textFieldView)
            } else {
                textFieldView
            }
        }
    }
    var secureFieldView: some View {
        SecureField("", text: $textVal)
            .textContentType(contentType ?? .password)
            .disableAutocorrection(true)
    }
    var textFieldView: some View {
        TextField("", text: $textVal, onCommit: onSubmit)
            .textContentType(contentType)
            .keyboardType(keyboardType ?? .default)
            .autocapitalization(disableAutoFeatures() ? .none : .sentences)
            .disableAutocorrection(disableAutoFeatures() ? true : false)
            .submitLabeliOS15(submitLabelType)
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
class CleanTextFieldVM: ObservableObject {
    let focusable: Bool
    @Published
    var fieldFocused: Bool
    init(focusable: Bool = false) {
        self.focusable = focusable
        self.fieldFocused = focusable
    }
}
struct FocusedTextField<Content: View>: View {
    @Binding
    var focused: Bool
    @Binding
    var text: String
    let onSubmit: () -> ()
    let content: Content
    var body: some View {
        LegacyTextField(isFirstResponder: $focused, text: $text, onSubmit: onSubmit)
    }
    @available(iOS 15.0, *)
    private struct FocusedTextFieldiOS15<Content: View>: View {
        @Binding
        var isFocused: Bool
        let content: Content
        @FocusState
        private var focusState: Bool
        var body: some View {
            content
                .focused($focusState)
                .onAppear {
                    focusState = isFocused
                }
                .onChange(of: isFocused) { focused in
                    focusState = focused
                }
        }
    }
    private struct LegacyTextField: UIViewRepresentable {
        @Binding
        var isFirstResponder: Bool
        @Binding
        var text: String
        let onSubmit: () -> ()
        var configuration = { (view: UITextField) in }
        func makeUIView(context: Context) -> UITextField {
            let textField = UITextField()
            textField.returnKeyType = UIReturnKeyType.search
            textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textField.addTarget(context.coordinator, action: #selector(Coordinator.textViewDidChange), for: .editingChanged)
            textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingEnd), for: .editingDidEndOnExit)
            textField.delegate = context.coordinator
            return textField
        }
        func updateUIView(_ uiView: UITextField, context: Context) {
            uiView.text = text
            configuration(uiView)
            if uiView.isFirstResponder != isFirstResponder {
                switch isFirstResponder {
                case true: uiView.becomeFirstResponder()
                case false: uiView.resignFirstResponder()
                }
            }
        }
        func makeCoordinator() -> Coordinator {
            Coordinator($text, isFirstResponder: $isFirstResponder, onSubmit: onSubmit)
        }
        final class Coordinator: NSObject, UITextFieldDelegate {
            @Binding
            var text: String
            @Binding
            var isFirstResponder: Bool
            let onSubmit: () -> ()
            init(_ text: Binding<String>, isFirstResponder: Binding<Bool>, onSubmit: @escaping () -> ()) {
                self._text = text
                self._isFirstResponder = isFirstResponder
                self.onSubmit = onSubmit
            }

            @objc func textViewDidChange(_ textField: UITextField) {
                self.text = textField.text ?? ""
            }
            func textFieldDidBeginEditing(_ textField: UITextField) {
                DispatchQueue.main.async {
                    self.isFirstResponder = true
                }
            }
            @objc func textFieldEditingEnd(_ textField: UITextField) {
                self.isFirstResponder = false
                self.onSubmit()
            }
        }
    }
}

struct CleanTextField_Previews: PreviewProvider {
    static var previews: some View {
        CleanTextField(viewModel: CleanTextFieldVM(focusable: true), textVal: .constant(""), hint: "Some hint")
    }
}
