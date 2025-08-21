//
//  PaymentViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 28/9/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

class PaymentViewModel: ObservableObject {
    @Published
    var state = NetworkingState.inited
    @Published
    var message: String?
    
    private var disposeBag = DisposeBag()
    
    func verifyPaymentOnServer(account: Account, refererUrl: URL?) {
        let apiRequest = APIRequest()
        state = .processing
        apiRequest.verifyPayment(for: account, refererUrl: refererUrl)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.state = .failed
                default: break
                }
            }) { response in
                self.message = response.message
                if response.success {
                    self.state = .success
                } else {
                    self.state = .failed
                }
            }
            .store(in: disposeBag)
    }
}
