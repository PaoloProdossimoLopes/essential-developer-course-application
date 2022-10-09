//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Paolo Prodossimo Lopes on 08/10/22.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)
    typealias RetrieveCompletion = ((Error?) -> Void)
    
    func deleteCache(completion: @escaping DeletionCompletion)
    func insertCache(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrieveCompletion)
}
