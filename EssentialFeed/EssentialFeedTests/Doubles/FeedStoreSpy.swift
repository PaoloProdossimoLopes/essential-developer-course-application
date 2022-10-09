import Foundation
import EssentialFeed

final class FeedStoreSpy: FeedStore {
    
    enum RecievedMessages: Equatable {
        case deleteCache
        case insert([LocalFeedImage], Date)
    }
    
    private(set) var recievedMessages = [RecievedMessages]()
    private var deletionsCompletion = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    
    //MARK: - Methods
    func deleteCache(completion: @escaping DeletionCompletion) {
        deletionsCompletion.append(completion)
        recievedMessages.append(.deleteCache)
    }
    
    func insertCache(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        recievedMessages.append(.insert(items, timestamp))
        insertionCompletions.append(completion)
    }
    
    //MARK: - Spies
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionsCompletion[index](error)
    }
    
    func completeDeletionSuccessfull(at index: Int = 0) {
        deletionsCompletion[index](nil)
    }
    
    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfull(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
