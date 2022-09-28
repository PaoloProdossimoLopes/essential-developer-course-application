public protocol HTTPClient {
    func get(from url: URL, completion: @escaping ((HTTPClientResult) -> Void))
}
