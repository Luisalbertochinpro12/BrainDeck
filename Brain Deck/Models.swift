import Foundation

// MARK: - 1. Flashcard (Tarjeta Individual)
struct Flashcard: Identifiable, Codable, Equatable {
    // Necesitas un ID único para usar ForEach correctamente
    var id = UUID()
    
    var question: String
    var answer: String
    
    // Propiedades para la Repetición Espaciada
    var masteryLevel: Int = 0 // Nivel de dominio (ej: 0=nuevo, 1, 2, 3...)
    var nextReviewDate: Date = Date() // Próxima fecha de revisión
    
    // Función auxiliar para mostrar el nivel de dominio como texto (opcional)
    var masteryLevelText: String {
        switch masteryLevel {
        case 0: return "Nuevo"
        case 1: return "Poco Dominado"
        case 2: return "Regular"
        case 3: return "Bien"
        default: return "Avanzado"
        }
    }
}

// MARK: - 2. Deck (Mazo de Tarjetas)
struct Deck: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var cards: [Flashcard]
    
    var cardCount: Int {
        cards.count
    }
    
    // Datos de ejemplo para el inicio/errores
    static var sampleDecks: [Deck] {
        return [
            Deck(name: "Capitales del Mundo", cards: [
                Flashcard(question: "Capital de Japón", answer: "Tokio", masteryLevel: 3, nextReviewDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!),
                Flashcard(question: "¿Río Nilo?", answer: "África", masteryLevel: 1, nextReviewDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!)
            ]),
            Deck(name: "Programación Swift", cards: [])
        ]
    }
}
