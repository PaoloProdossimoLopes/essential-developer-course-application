public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}
