//
//  LoginViewItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 1/3/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct LoginViewItem {
    let onSignIn: (Account) -> ()
    let onDismiss: () -> ()
    var bannerMsg: String?
}
