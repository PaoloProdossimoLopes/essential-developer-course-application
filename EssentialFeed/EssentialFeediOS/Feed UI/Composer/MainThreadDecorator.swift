import Foundation
import EssentialFeed

final class MainThreadDecorator<T> {
    
    private let decoratee: T
    
    init(_ decoratee: T) {
        self.decoratee = decoratee
    }
    
    func onMainIfNeeded(_ completion: @escaping () -> Void) {
        
        guard Thread.isMainThread else {
            return DispatchQueue.main.async(execute: completion)
        }
        
        return completion()
    }
}

extension MainThreadDecorator: IFeedLoader where T == IFeedLoader {
    func load(completion: @escaping ((EssentialFeed.FeedResult) -> Void)) {
        decoratee.load { [weak self] result in
            self?.onMainIfNeeded { completion(result) }
        }
    }
}

extension MainThreadDecorator: FeedImageDataLoader where T == FeedImageDataLoader {
    func loadImageData(from url: URL, completion: @escaping ((FeedImageDataLoader.Result) -> Void)) -> FeedImageDataLoaderTask {
        decoratee.loadImageData(from: url) { [weak self] result in
            self?.onMainIfNeeded { completion(result) }
        }
    }
}
