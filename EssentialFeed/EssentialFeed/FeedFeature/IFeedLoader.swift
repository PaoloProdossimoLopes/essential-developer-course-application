public protocol IFeedLoader {
    associatedtype Error: Swift.Error
    func load(completion: @escaping ((FeedResult<Error>) -> Void))
}
