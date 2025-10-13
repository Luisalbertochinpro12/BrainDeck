import Foundation

// MARK: - 1. Estructura de la Tarjeta (Flashcard)
struct Flashcard: Identifiable, Hashable {
    let id = UUID()         // Identificador único (necesario para SwiftUI)
    var question: String    // El texto del frente de la tarjeta
    var answer: String      // El texto del reverso (la respuesta)
    var masteryLevel: Int = 0 // Nivel de dominio (ej: 0=Nuevo, 1=Difícil, 2=Fácil)
}

// MARK: - 2. Estructura del Mazo (Deck)
struct Deck: Identifiable {
    let id = UUID()
    var name: String            // Nombre del mazo (ej: "Programación Básica")
    var cards: [Flashcard]      // Un arreglo con todas las tarjetas que contiene
    
    // Propiedad calculada para saber cuántas tarjetas tiene
    var cardCount: Int {
        return cards.count
    }
}

// MARK: - 3. Datos de Prueba
extension Deck {
    // Un mazo de ejemplo para poder probar la vista de la lista
    static let sampleDeck = Deck(
        name: "Programación Básica",
        cards: [
            Flashcard(question: "¿Lenguaje principal de iOS?", answer: "Swift"),
            Flashcard(question: "¿Qué es un 'struct'?", answer: "Un tipo de valor usado para modelar datos."),
            Flashcard(question: "¿Qué significa CRUD?", answer: "Create, Read, Update, Delete")
        ]
    )
    
    // Una lista estática de varios mazos de ejemplo para la vista principal
    static let sampleDecks: [Deck] = [
        sampleDeck,
        Deck(name: "Capitales del Mundo", cards: [Flashcard(question: "¿Capital de Francia?", answer: "París")]),
        Deck(name: "Historia de México", cards: [])
    ]
}
