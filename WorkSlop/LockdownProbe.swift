import Foundation
import Network

/// Lockdown reachability probe for the on-device engine.
///
/// The on-device route talks to THIS phone's own lockdownd over the
/// loopback WireGuard tunnel, authenticated with the imported pairing
/// record (the same design SideStore-class apps use). This probe does
/// the first real steps of that session:
///
/// 1. Enumerate the tunnel (utun) addresses on this device.
/// 2. Open a TCP connection to lockdownd (port 62078) on each.
/// 3. Speak the lockdown plist protocol: length-prefixed plist,
///    `QueryType` -> lockdownd answers its type string.
///
/// A reachable lockdownd is reported as a fact. The TLS pairing
/// upgrade (StartSession with the pairing record's identity) is the
/// next engine step and is NOT claimed here: engine status stays
/// "reachable, session unverified" until that lands, and Apply keeps
/// its gate. Nothing in this file pretends a restore happened.
enum LockdownProbe {
    struct Result: Equatable {
        var tunnelAddress: String?
        var lockdownReachable: Bool
        var lockdownType: String?

        var summary: String {
            guard let addr = tunnelAddress else {
                return "No VPN tunnel address on this device — start WireGuard first."
            }
            if lockdownReachable {
                return "Lockdown reachable at \(addr):62078 (\(lockdownType ?? "lockdownd")). Pairing session (TLS) is the next engine step."
            }
            return "Tunnel address \(addr) found, but lockdownd did not answer on port 62078."
        }
    }

    /// All IPv4/IPv6 addresses bound to utun* interfaces.
    static func tunnelAddresses() -> [String] {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return [] }
        defer { freeifaddrs(addrs) }
        var out: [String] = []
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            guard let sa = ptr.pointee.ifa_addr else { continue }
            let name = String(cString: ptr.pointee.ifa_name)
            guard name.hasPrefix("utun") else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let family = sa.pointee.sa_family
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else { continue }
            let len = family == UInt8(AF_INET) ? socklen_t(MemoryLayout<sockaddr_in>.size)
                                              : socklen_t(MemoryLayout<sockaddr_in6>.size)
            if getnameinfo(sa, len, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                let addr = String(cString: host)
                if addr != "127.0.0.1" && !addr.hasPrefix("fe80") && !out.contains(addr) {
                    out.append(addr)
                }
            }
        }
        return out
    }

    /// Probe each tunnel address for a lockdownd answer. Completes
    /// with the first positive result, or a negative one after all
    /// candidates timed out (2 s each).
    static func probe(completion: @escaping (Result) -> Void) {
        let candidates = tunnelAddresses()
        guard let first = candidates.first else {
            completion(Result(tunnelAddress: nil, lockdownReachable: false, lockdownType: nil))
            return
        }
        probeCandidate(first) { type in
            completion(Result(tunnelAddress: first,
                              lockdownReachable: type != nil,
                              lockdownType: type))
        }
    }

    private static func probeCandidate(_ host: String, completion: @escaping (String?) -> Void) {
        let conn = NWConnection(host: NWEndpoint.Host(host),
                                port: 62078, using: .tcp)
        var finished = false
        let finish: (String?) -> Void = { value in
            guard !finished else { return }
            finished = true
            conn.cancel()
            completion(value)
        }
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                sendQueryType(on: conn, finish: finish)
            case .failed, .cancelled:
                finish(nil)
            default:
                break
            }
        }
        conn.start(queue: .global(qos: .userInitiated))
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            finish(nil)
        }
    }

    /// Length-prefixed plist QueryType, per the lockdown wire format.
    private static func sendQueryType(on conn: NWConnection,
                                      finish: @escaping (String?) -> Void) {
        let request: [String: Any] = [
            "Label": "WorkSlop",
            "Request": "QueryType",
        ]
        guard let body = try? PropertyListSerialization.data(
            fromPropertyList: request, format: .xml, options: 0) else {
            finish(nil)
            return
        }
        var length = UInt32(body.count).bigEndian
        var packet = Data(bytes: &length, count: 4)
        packet.append(body)
        conn.send(content: packet, completion: .contentProcessed { _ in
            receiveResponse(on: conn, finish: finish)
        })
    }

    private static func receiveResponse(on conn: NWConnection,
                                        finish: @escaping (String?) -> Void) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { header, _, _, _ in
            guard let header, header.count == 4 else { finish(nil); return }
            let length = header.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
            guard length > 0, length < 1_000_000 else { finish(nil); return }
            conn.receive(minimumIncompleteLength: Int(length),
                         maximumLength: Int(length)) { body, _, _, _ in
                guard let body,
                      let plist = try? PropertyListSerialization.propertyList(
                        from: body, options: [], format: nil),
                      let dict = plist as? [String: Any] else {
                    finish(nil)
                    return
                }
                finish(dict["Type"] as? String)
            }
        }
    }
}
