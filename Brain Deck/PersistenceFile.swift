// PersistenceHelper.swift
import Foundation

extension FileManager {
    // Definimos una propiedad estática que usa el App Group.
    static var sharedStoreURL: URL? {
        // ¡USA TU NOMBRE DE GRUPO!
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.taam.braindeck")?
            .appendingPathComponent("decks.json")
    }
}
