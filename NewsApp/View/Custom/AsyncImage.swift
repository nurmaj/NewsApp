//
//  AsyncImage.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 10/3/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Combine

struct AsyncImage<Placeholder: View, Failure: View>: View {
    @StateObject
    private var loader: ImageLoader
    private let placeholder: Placeholder
    private let failure: Failure
    private let completion: (LoadState, UIImage?) -> ()
    //private let onLoaded: (UIImage) -> ()
    //private var debug: Bool
    //@Environment(\.imageCache) var imageCache
    init(url: URL, onlyCached: Bool = false, @ViewBuilder placeholder: @escaping () -> Placeholder, @ViewBuilder failure: @escaping () -> Failure, completion: @escaping (LoadState, UIImage?) -> () = { _,_ in }) {//@ViewBuilder
        //self.onlyCached = onlyCached
        self.completion = completion
        self.placeholder = placeholder()
        self.failure = failure()
        //loader.setupLoader(url: url, onlyCached: onlyCached)
        self._loader = StateObject(wrappedValue: ImageLoader(url: url, onlyCached: onlyCached))//, cache: Environment(\.imageCache).wrappedValue
    }
    
    var body: some View {
        content
            .onAppear(perform: loader.load)
    }
    @ViewBuilder
    private var content: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
                .onAppear { self.completion(.displayed, image) }
        } else if loader.state == .failure {
            failure
                .onAppear{ self.completion(.failure, nil) }
        } else {
            placeholder
        }
    }
    private class ImageLoader: ObservableObject {
        @Published
        var image: UIImage?
        @Published
        var state = LoadState.notStarted
        /*@Published
        var url: URL?*/
        private let url: URL
        private let onlyCached: Bool
        
        private var cancellable: AnyCancellable?
        
        private let cache = AsyncImageCache.shared
        
        init(url: URL, onlyCached: Bool) {
            self.url = url
            self.onlyCached = onlyCached
            load()
        }
        deinit {
            cancel()
        }
        
        func load() {
            if self.state == .loading {
                return
            }
            if let image = cache[url] {
                self.image = image
                return
            }
            if onlyCached {
                return
            }
            cancellable = URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { (data, response) in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw RemoteError.internalError
                    }
                    guard 200..<300 ~= httpResponse.statusCode else {
                        throw RemoteError.serverError(httpResponse.statusCode)
                    }
                    return UIImage(data: data)
                }
                .handleEvents(receiveSubscription: { [weak self] _ in self?.onStart() },
                              receiveOutput: { [weak self] in self?.cacheResult($0) },
                              receiveCancel: { [weak self] in self?.onFinish() })
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] result in
                    switch(result) {
                    case .failure(_):
                        self?.state = .failure
                    default:
                        self?.onFinish()
                        break
                    }
                }, receiveValue: { [weak self] in self?.image = $0 })
        }
        private func onStart() {
            self.state = .loading
        }
        
        private func onFinish() {
            self.state = .finished
        }
        private func cacheResult(_ image: UIImage?) {//, _ url: URL
            image.map {
                cache.storeImage($0, for: url)
            }
        }
        func cancel() {
            cancellable?.cancel()
        }
    }
    enum LoadState {
        case notStarted, loading, finished, displayed, failure
    }
}
// Image Cache Layer
protocol ImageCache {
    func image(for url: URL) -> UIImage?
    func storeImage(_ image: UIImage?, for url: URL)
    func cleanImage(for url: URL)
    subscript(_ url: URL) -> UIImage? { get set }
}
final class AsyncImageCache {
    private lazy var cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = config.countLimit
        cache.totalCostLimit = config.memoryLimit
        return cache
    }()
    
    private let config: Config = Config.defaultConfig
    struct Config {
        let countLimit: Int
        let memoryLimit: Int
        static let defaultConfig = Config(countLimit: 1000, memoryLimit: 134217728 /* 128 MB */)
    }
    static let shared = AsyncImageCache()
    //private let lock = NSLock()//The NSLock instance is used to provide mutually exclusive access and make the cache thread-safe.
}
extension AsyncImageCache: ImageCache {
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    func storeImage(_ image: UIImage?, for url: URL) {
        guard let image = image else {
            return cleanImage(for: url)
        }
        cache.setObject(image, forKey: url as NSURL)
    }
    func cleanImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
}
extension AsyncImageCache {
    subscript(url: URL) -> UIImage? {
        get { image(for: url) }
        set { self.storeImage(newValue, for: url) }
    }
}
