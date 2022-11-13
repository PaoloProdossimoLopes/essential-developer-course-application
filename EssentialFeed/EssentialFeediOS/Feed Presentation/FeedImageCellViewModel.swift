import Foundation
import EssentialFeed

final class FeedImageCellViewModel {
    
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




struct FeedImagePresentableModel {
    let data: Data?
    let description: String?
    let location: String?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        return location != nil
    }
}

protocol FeedImageCellLoadViewProtocol {
    func display(model: FeedImagePresentableModel)
}

final class FeedImageCellPresenter {
    
    //MARK: - Properties
    private var task: FeedImageDataLoaderTask?
    private let dataValidator: (Data) -> Bool
    
    var presentView: FeedImageCellLoadViewProtocol?
    
    //MARK: - Initializer
    init(dataValidator: @escaping (Data) -> Bool) {
        self.dataValidator = dataValidator
    }
    
    func didStartLoadingImageData(for model: FeedImage) {
        presentView?.display(model: .init(
            data: nil,
            description: model.description,
            location: model.location,
            isLoading: true,
            shouldRetry: false
        ))
    }
    
    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        guard dataValidator(data) else {
            return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
        }
        
        presentView?.display(model: .init(
            data: data,
            description: model.description,
            location: model.location,
            isLoading: false,
            shouldRetry: false
        ))
    }
    
    private struct InvalidImageDataError: Error { }
    
    func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        presentView?.display(model: .init(
            data: nil,
            description: model.description,
            location: model.location,
            isLoading: false,
            shouldRetry: true
        ))
    }
}
