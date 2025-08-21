//
//  RemoteImage.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 10/3/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Combine

fileprivate struct RemoteImage<Placeholder: View>: View {
    private let placeholder: Placeholder
    @StateObject
    private var loader: Loader
    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        self.placeholder = placeholder()
        self._loader = StateObject(wrappedValue: Loader(url))
    }
    var body: some View {
        content
            .onAppear{ loader.load() }
    }
    private var content: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder
            }
        }
    }
    private class Loader: ObservableObject {
        private let url: URL
        @Published
        var image: UIImage?
        private var cancellable: AnyCancellable?
        var state = LoadState.loading
        init(_ url: URL) {
            self.url = url
        }
        deinit {
            cancel()
        }
        func load() {
            cancellable = URLSession.shared.dataTaskPublisher(for: url)
                //.map { UIImage(data: $0.data) }
                .tryMap { (data, response) in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw RemoteError.internalError
                    }
                    guard 200..<300 ~= httpResponse.statusCode else {
                        throw RemoteError.serverError(httpResponse.statusCode)
                    }
                    /*200...299 ~= response.statusCode else {
                        throw RemoteError.in
                    }*/
                    return UIImage(data: data)
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    switch(result) {
                    case .failure(_):
                        self.state = .failure
                    default: break
                    }
                }, receiveValue: { [weak self] in self?.image = $0 })
        }
        func cancel() {
            cancellable?.cancel()
        }
    }
    enum LoadState {
        case loading, success, failure
    }
}
