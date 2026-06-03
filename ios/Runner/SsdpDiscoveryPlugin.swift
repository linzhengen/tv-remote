import Flutter
import Network
import Foundation

/// Handles SSDP discovery on iOS using Network.framework,
/// which does NOT require the multicast entitlement that personal teams can't get.
class SsdpDiscoveryPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.seion.tvRemote/ssdp_discovery",
            binaryMessenger: registrar.messenger()
        )
        let instance = SsdpDiscoveryPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "discover" {
            let timeout = (call.arguments as? [String: Any])?["timeout"] as? Double ?? 8.0
            Self.discover(timeout: timeout) { devices in
                result(devices)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    /// Sends SSDP M-SEARCH and collects Panasonic TV responses.
    /// Uses NWMulticastGroup (iOS 14+) to avoid the multicast entitlement.
    /// On iOS <14, returns empty so the Dart-side raw sockets handle it.
    static func discover(timeout: TimeInterval, completion: @escaping ([[String: Any]]) -> Void) {
        guard #available(iOS 14.0, *) else {
            completion([])
            return
        }

        let multicastEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host("239.255.255.250"),
            port: NWEndpoint.Port(integerLiteral: 1900)
        )

        // Create multicast group with unicast traffic enabled (needed for SSDP)
        let multicastGroup: NWMulticastGroup
        do {
            multicastGroup = try NWMulticastGroup(
                for: [multicastEndpoint],
                disableUnicast: false
            )
        } catch {
            completion([])
            return
        }

        // Require WiFi interface so we don't try cellular
        let params = NWParameters.udp
        params.requiredInterfaceType = .wifi
        params.allowLocalEndpointReuse = true

        let group = NWConnectionGroup(with: multicastGroup, using: params)
        var devices: [[String: Any]] = []
        var seenIPs = Set<String>()
        let queue = DispatchQueue(label: "ssdp.discovery")
        var didSend = false
        var completed = false

        func finish() {
            guard !completed else { return }
            completed = true
            group.cancel()
            completion(devices)
        }

        func sendSearch() {
            guard !didSend else { return }
            didSend = true

            let sts = [
                "urn:panasonic-com:service:p00NetworkControl:1",
                "ssdp:all",
                "upnp:rootdevice",
            ]
            for st in sts {
                let message =
                    "M-SEARCH * HTTP/1.1\r\n"
                    + "HOST: 239.255.255.250:1900\r\n"
                    + "MAN: \"ssdp:discover\"\r\n"
                    + "MX: 3\r\n"
                    + "ST: \(st)\r\n\r\n"
                group.send(content: message.data(using: .utf8)!) { _ in }
            }
        }

        group.setReceiveHandler(maximumMessageSize: 65535) { message, content, _ in
            guard !completed,
                  let content = content,
                  let response = String(data: content, encoding: .utf8)
            else { return }

            let lower = response.lowercased()
            let isPanasonic = lower.contains("panasonic")
                || lower.contains("viera")
                || lower.contains("panasonic-com")
            guard isPanasonic else { return }

            // Extract IP from LOCATION header (most reliable)
            guard let locationRange = response.range(
                of: "LOCATION:\\s*(.+)", options: .regularExpression)
            else { return }

            var location = String(response[locationRange])
                .replacingOccurrences(of: "LOCATION:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            location = location
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "https://", with: "")
            let deviceIP = location.components(separatedBy: ":")[0]
                .components(separatedBy: "/")[0]

            guard !seenIPs.contains(deviceIP) else { return }
            seenIPs.insert(deviceIP)

            var device: [String: Any] = [
                "name": "Panasonic TV (\(deviceIP))",
                "ipAddress": deviceIP,
                "brand": "panasonic",
                "port": 55000,
            ]

            // Extract model name from SERVER header
            if let serverRange = response.range(
                of: "SERVER:\\s*(.+)", options: .regularExpression)
            {
                let server = String(response[serverRange])
                    .replacingOccurrences(of: "SERVER:", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let modelRange = server.range(
                    of: "Panasonic[- ](\\w+)", options: .regularExpression)
                {
                    let model = String(server[modelRange])
                        .replacingOccurrences(of: "Panasonic-", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: "Panasonic ", with: "", options: .caseInsensitive)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    device["modelName"] = model
                }
            }

            devices.append(device)
        }

        group.stateUpdateHandler = { state in
            if case .ready = state {
                sendSearch()
            }
        }

        group.start(queue: queue)

        // Fallback send in case .ready never fires
        queue.asyncAfter(deadline: .now() + 1) {
            sendSearch()
        }

        // Complete after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            finish()
        }
    }
}
