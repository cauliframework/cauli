import UIKit

enum Result<Type> {
    case error(Error)
    case result(Type)
}

protocol Record {
    var identifier: UUID { get }
//    var createdAt: Date { get }
//    var storedAt: Date { get }
    var originalRequest: URLRequest { get }
    var designatedRequest: URLRequest { get }
    var result: Result<(URLResponse, Data?)> { get }
//    var additionalInformation: [String: Codable] { get }
}

protocol Floret {
    func willRequest(_ record: Record) -> Record
    func didRespond(_ record: Record) -> Record
}

protocol Storage {
    func store(_ record: Record)
    func records(_ count: Int, after: Record?) -> [Record]
}

final class Cauli {
    
    public var enabled: Bool
    private let storage: Storage
    
    init(_ florets: [Floret]) {
        fatalError("implement me")
    }
    
}
