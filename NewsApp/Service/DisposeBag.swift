//
//  CancelStore.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 23/2/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Combine

final class DisposeBag {
    fileprivate(set) var subscriptions = Set<AnyCancellable>()
    
    func cancel() {
        subscriptions.removeAll()
    }
}

extension AnyCancellable {
    func store(in disposeBag: DisposeBag) {
        disposeBag.subscriptions.insert(self)
    }
}
