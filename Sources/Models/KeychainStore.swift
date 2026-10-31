import Foundation
import Security

/// Zugangsdaten gehoeren in den Schluesselbund, nicht in die Einstellungs-
/// datei (Spec 11.4). Mehr als Lesen, Schreiben und Loeschen braucht v1 nicht.
enum KeychainStore {
    private static let service = "HealthWake"

    static func set(_ secret: String, account: String) throws {
        var query = baseQuery(account: account)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = Data(secret.utf8)
        // Erst nach der ersten Entsperrung lesbar -- dieselbe Klasse wie die
        // uebrigen dauerhaften Daten, damit eine Aktion im Hintergrund nach
        // einem Neustart ueberhaupt an das Geheimnis kommt. ThisDeviceOnly,
        // weil die Oberflaeche zusagt, dass das Geheimnis in keiner Sicherung
        // landet.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
    }

    static func get(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

enum KeychainError: Error, Equatable {
    case status(OSStatus)
}
