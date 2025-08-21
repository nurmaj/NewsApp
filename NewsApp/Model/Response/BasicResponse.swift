//
//  BasicResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 30/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
protocol BasicResponse {
    var success: Bool { get }
    var message: String? { get }
}
