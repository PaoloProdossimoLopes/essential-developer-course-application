public enum FeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension FeedResult: Equatable where Error: Equatable {
    
}
