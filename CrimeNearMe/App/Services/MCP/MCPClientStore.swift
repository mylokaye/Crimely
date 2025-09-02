import Foundation
import Combine

#if canImport(MCP)
import MCP
typealias _MCPClientType = MCP.Client

/// ObservableObject wrapper exposing a real MCP client when MCP is available.
final class MCPClientStore: ObservableObject {
    let client: _MCPClientType
    @Published var isConnected: Bool = false

    init(client: _MCPClientType) {
        self.client = client
    }

    convenience init(name: String = "CrimeNearMe", version: String = "1.0.0") {
        self.init(client: _MCPClientType(name: name, version: version))
    }
}

#else

/// Fallback stub for builds without the MCP package.
final class MCPClientStore: ObservableObject {
    @Published var isConnected: Bool = false

    init() {}
}

#endif
