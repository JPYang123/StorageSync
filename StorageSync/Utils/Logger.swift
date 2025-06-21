import Foundation

struct Logger {
    static func log(_ error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}
