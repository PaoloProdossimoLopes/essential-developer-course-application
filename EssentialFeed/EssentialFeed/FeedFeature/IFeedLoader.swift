public protocol IFeedLoader {
    func load(completion: @escaping ((FeedResult) -> Void))
}
