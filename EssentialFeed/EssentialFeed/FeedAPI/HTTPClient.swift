public protocol HTTPClient {
    func get(from url: URL, completion: @escaping ((Error) -> Void))
}
