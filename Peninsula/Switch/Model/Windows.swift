import Foundation

final class Windows: ObservableObject, Collection {
    var id: UUID = UUID()
    @Published var coll: [Window] = []
    typealias E = Window
    static var shared = Windows()
}
