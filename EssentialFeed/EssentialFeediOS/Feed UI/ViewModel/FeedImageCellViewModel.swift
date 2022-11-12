import Foundation
import EssentialFeed

final class FeedImageCellViewModel {
    typealias Observer<T> = (T) -> Void
    
    //MARK: - Properties
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private let dataValidator: (Data) -> Bool
    
    var onLoadChange: Observer<Data?>?
    var onImageLoadingStateChange: Observer<Bool>?
    var onShouldRetryImageLoadStateChange: Observer<Bool>?
    
    //MARK: - Initializer
    init(imageLoader: FeedImageDataLoader, model: FeedImage, dataValidator: @escaping (Data) -> Bool) {
        self.imageLoader = imageLoader
        self.model = model
        self.dataValidator = dataValidator
    }
    
    //MARK: - Getters
    var description: String? { model.description }
    var location: String? { model.location }
    var hasLocaltion: Bool { location != nil }
    
    //MARK: - Methods
    func loadImageData() {
        onImageLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
        task = imageLoader.loadImageData(from: model.image) { [weak self] result in
            self?.handle(result)
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    //MARK: - Helpers
    private func handle(_ result: Result<Data, Error>) {
        if let data = try? result.get(), dataValidator(data) {
            onLoadChange?(data)
        } else {
            onShouldRetryImageLoadStateChange?(true)
        }
        
        onImageLoadingStateChange?(false)
    }
}
