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

// MARK: - 3. QuizQuestion (Estructura para el Cuestionario)
struct QuizQuestion: Identifiable {
    let id = UUID()
    let card: Flashcard        // Referencia a la tarjeta original
    let questionText: String   // El enunciado (ej: "Ensamblador")
    let correctAnswer: String  // La respuesta correcta (ej: "Lenguaje a nivel computadora")
    let options: [String]      // Las 4 opciones mezcladas (incluida la correcta)
}

// MARK: - 4. Extensión para generar el Cuestionario (Lógica de Distractores Corregida)
extension Deck {
    
    func generateQuizQuestions() -> [QuizQuestion] {
        // Mínimo 4 tarjetas para poder tener 1 correcta y 3 distractores.
        guard self.cards.count >= 4 else { return [] }

        var quizQuestions: [QuizQuestion] = []
        
        // 1. Obtenemos TODAS las respuestas (answers) del MAZO ACTUAL.
        let allAnswers = self.cards.map { $0.answer }

        // 2. Iterar sobre las tarjetas para crear una pregunta por cada una.
        for card in self.cards {
            
            // La respuesta correcta es el campo 'answer'.
            let correctAnswer = card.answer
            
            // El texto de la pregunta es el campo 'question'.
            let questionText = card.question
            
            // 3. Generar 3 respuestas incorrectas (distractores)
            var incorrectAnswers = allAnswers
                // Filtramos: Excluimos la respuesta correcta.
                .filter { $0 != correctAnswer }
                .shuffled() // Barajamos
                .prefix(3)  // Tomamos un máximo de 3
            
            // 4. Construir las opciones mezcladas.
            var options = [correctAnswer]
            options.append(contentsOf: incorrectAnswers) // Añadimos los distractores
            
            // 5. Crear la pregunta (Respetando el orden de inicialización: questionText, correctAnswer, options)
            let question = QuizQuestion(
                card: card,
                questionText: "Responde: \(questionText)",
                correctAnswer: correctAnswer,
                options: options.shuffled()
            )
            
            quizQuestions.append(question)
        }
        
        // Barajar el orden de las preguntas del quiz
        return quizQuestions.shuffled()
    }
}
