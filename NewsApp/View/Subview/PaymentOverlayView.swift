//
//  PaymentOverlayView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 5/10/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct PaymentOverlayView: View {
    @Binding
    var presentOverlay: Bool
    @Binding
    var paymentResult: SubscriptionState
    let refererUrl: URL?
    let user: Account?
    let subscriptionConf: SubscriptionConfig?
    let onDismiss: (NetworkingState) -> Void
    @StateObject
    var viewModel = PaymentViewModel()
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            VStack {
                if viewModel.state == .processing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("GreyTint")))
                        .frame(width: 32, height: 24)
                    Text("payment_verify")
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 24)
                } else if viewModel.state == .failed {
                    if let message = viewModel.message {
                        Text(message)
                            .foregroundColor(Color("ErrorTint"))
                    }
                    Text(paymentResult == .paymentFailed ? "payment_failure" : "payment_verify_failure")
                    if paymentResult == .paymentSuccess {
                        Button(action: {
                            if let account = user {
                                viewModel.verifyPaymentOnServer(account: account, refererUrl: self.refererUrl)
                            }
                        }) {
                            Text("retry_one_more")
                                .foregroundColor(Color.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("GreyLight"))
                                )
                        }
                    }
                    if let contacts = self.subscriptionConf?.contacts {
                        Text("payment_verify_contact")
                            .padding(.bottom, 4)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(contacts, id: \.self) { contact in
                            Text("\(contact.label != nil ? "\(contact.label ?? ""): " : "")\(contact.getContactInfo())")
                                .accentColor(Color.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else if viewModel.state == .success {
                    Image(systemName: "checkmark.seal")
                        .font(.largeTitle)
                        .foregroundColor(Color("PrimaryMono"))
                    Text("thanks")
                        .font(.title2)
                    Text("payment_verify_success")
                        .font(.body)
                }
                if viewModel.state == .failed || viewModel.state == .success {
                    CustomDivider()
                    Button(action: {
                        self.presentOverlay = false
                        self.onDismiss(viewModel.state)
                    }, label: {
                        Text("close")
                            .font(.callout)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                    })
                }
            }
            .foregroundColor(Color("BlackTint"))
            .onAppear(perform: onPaymentOverlayAppear)
            .frame(maxWidth: .infinity, minHeight: 150)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("WhiteDarker"))
            )
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    private func onPaymentOverlayAppear() {
        if let _ = user {
            if paymentResult == .paymentSuccess {
                viewModel.state = .success
            } else {
                viewModel.state = .failed
            }
        }
    }
}

struct PaymentOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentOverlayView(presentOverlay: .constant(true), paymentResult: .constant(.none), refererUrl: nil, user: nil, subscriptionConf: SubscriptionConfig(buyOrSubscribeAction: "", successUrl: "", failureUrl: "", contacts:
        [ContactItem(email: nil, phone: "+996 (554) 20-29-95", address: nil, label: "тел."),
        ContactItem(email: nil, phone: nil, address: "г. Бишкек, проспект Чынгыза Айтматова, 299/5", label: nil),
        ContactItem(email: "info@newsapp.media", phone: nil, address: nil, label: "E-mail")]), onDismiss: { _ in })
    }
}
