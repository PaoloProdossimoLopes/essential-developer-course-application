protocol IFeedLoader {
    func load(completion: @escaping ((FeedItem) -> Void))
}
