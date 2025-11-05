import SwiftUI

// MARK: - 1. Vista Principal del Cuestionario
struct QuizView: View {
    // Recibimos el Binding del mazo para poder actualizar la tarjeta después del quiz
    @Binding var deck: Deck
    
    // Estado para manejar el flujo del quiz
    @State private var quizQuestions: [QuizQuestion] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var score: Int = 0
    @State private var quizFinished: Bool = false // Controla si mostrar preguntas o resultados
    @State private var quizHasRun: Bool = false // <-- ¡NUEVA BANDERA!
    
    // Estado de la UI y navegación
    @State private var selectedAnswer: String? = nil
    @State private var showFeedback: Bool = false
    @Environment(\.dismiss) var dismiss // Para cerrar la vista modal (sheet)
    
    // Propiedad calculada para la pregunta actual
    var currentQuestion: QuizQuestion? {
        currentQuestionIndex < quizQuestions.count ? quizQuestions[currentQuestionIndex] : nil
    }
    
    // El quiz es válido si tiene 4 o más tarjetas
    var isQuizReady: Bool {
        deck.cards.count >= 4
    }
    
    // --- Lógica de Repetición Espaciada (Spaced Repetition) ---
    let reviewIntervals: [Int: Int] = [
        0: 0, 1: 1, 2: 3, 3: 7, 4: 14
    ]

    private func updateFlashcard(cardID: UUID, wasCorrect: Bool) {
        guard let cardIndex = deck.cards.firstIndex(where: { $0.id == cardID }) else { return }
        
        var card = deck.cards[cardIndex]
        
        if wasCorrect {
            card.masteryLevel += 1
        } else {
            card.masteryLevel = 0
        }
        
        let level = card.masteryLevel
        let days = reviewIntervals[level] ?? reviewIntervals.values.max() ?? 7
        
        card.nextReviewDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        deck.cards[cardIndex] = card
    }
    // -------------------------------------------------------------------
    
    // Función que se ejecuta al aparecer la vista
    private func setupQuiz() {
        // CORRECCIÓN: Si el quiz ya se ha cargado una vez (quizHasRun) y aún no ha terminado
        // (es decir, estamos navegando entre preguntas), no lo reinicies.
        print("🔍 setupQuiz() ejecutado — quizHasRun: \(quizHasRun), quizFinished: \(quizFinished)")

        if quizHasRun { return }
        
        if isQuizReady {
            self.quizQuestions = deck.generateQuizQuestions()
            self.currentQuestionIndex = 0
            self.score = 0
            self.quizFinished = false
            self.quizHasRun = true

            if quizQuestions.isEmpty {
                quizFinished = false
                return
            }
        }

    }
    
    // Función que se llama al seleccionar una respuesta
    func submitAnswer(answer: String) {
        selectedAnswer = answer
        showFeedback = true
        
        guard let question = currentQuestion else { return }
        
        let wasCorrect = (answer == question.correctAnswer)
        
        if wasCorrect {
            score += 1
        }
        
        // Aplica la lógica de Repetición Espaciada
        updateFlashcard(cardID: question.card.id, wasCorrect: wasCorrect)
    }
    
    // Función para avanzar a la siguiente pregunta
    func moveToNextQuestion() {
        selectedAnswer = nil
        showFeedback = false
        
        if currentQuestionIndex < quizQuestions.count - 1 {
            currentQuestionIndex += 1
        } else {
            quizFinished = true // El quiz ha terminado
            // No reseteamos quizHasRun aquí, lo dejamos en true para que el setup no corra.
        }
    }
    
    // MARK: - El body de la vista principal del Quiz
    var body: some View {
        Group {
            if isQuizReady {
                if quizFinished { // 1. Muestra los resultados si terminó
                    QuizResultsView(
                        score: score,
                        totalQuestions: quizQuestions.count,
                        // CRÍTICO: Pasamos la acción de cierre
                        dismissAction: dismiss.callAsFunction
                    )
                } else if let question = currentQuestion { // 2. Muestra la pregunta actual
                    QuizQuestionView(
                        question: question,
                        currentQuestionIndex: currentQuestionIndex,
                        totalQuestions: quizQuestions.count,
                        selectedAnswer: $selectedAnswer,
                        showFeedback: $showFeedback,
                        submitAction: submitAnswer,
                        nextAction: moveToNextQuestion
                    )
                } else {
                    Text("Cargando preguntas...")
                }
            } else {
                // 3. Muestra el mensaje si faltan tarjetas
                VStack(spacing: 20) {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("¡Mazo Demasiado Pequeño!")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Necesitas al menos **4 tarjetas** en el mazo para generar un cuestionario de opción múltiple con distractores.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    Button("Volver a la Lista") {
                        dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        // Llamada de inicialización, ahora protegida
        .onAppear(perform: setupQuiz)
        .navigationTitle("Cuestionario: \(deck.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cerrar") {
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 2. Vista de una Sola Pregunta (Componente)
struct QuizQuestionView: View {
    // ... (El código de QuizQuestionView sigue siendo el mismo) ...
    let question: QuizQuestion
    let currentQuestionIndex: Int
    let totalQuestions: Int
    
    @Binding var selectedAnswer: String?
    @Binding var showFeedback: Bool
    
    let submitAction: (String) -> Void
    let nextAction: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // Progreso
                HStack {
                    Text("Pregunta \(currentQuestionIndex + 1) de \(totalQuestions)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Pregunta
                Text(question.questionText)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Opciones de Respuesta
                VStack(spacing: 15) {
                    ForEach(question.options, id: \.self) { option in
                        QuizOptionButton(
                            option: option,
                            isSelected: selectedAnswer == option,
                            showFeedback: showFeedback,
                            isCorrect: option == question.correctAnswer,
                            action: {
                                if selectedAnswer == nil {
                                    submitAction(option)
                                }
                            }
                        )
                    }
                }
                .padding(.top, 20)
                
                // --- Feedback de Respuesta Incorrecta ---
                if showFeedback && selectedAnswer != question.correctAnswer {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Respuesta Correcta:")
                            .font(.callout)
                            .foregroundColor(.orange)
                        Text(question.correctAnswer)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Botón de Continuar
                if showFeedback {
                    Button(action: nextAction) {
                        Text(currentQuestionIndex < totalQuestions - 1 ? "Continuar" : "Finalizar Quiz")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.top, 40)
            .padding(.bottom)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 3. Botón de Opción (Componente Pequeño)
struct QuizOptionButton: View {
    // ... (El código de QuizOptionButton sigue siendo el mismo) ...
    let option: String
    let isSelected: Bool
    let showFeedback: Bool
    let isCorrect: Bool
    let action: () -> Void
    
    var backgroundColor: Color {
        if !showFeedback {
            return .gray.opacity(0.3)
        } else if isCorrect {
            return .green
        } else if isSelected && !isCorrect {
            return .red
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    var textColor: Color {
        if showFeedback && (isCorrect || isSelected) {
            return .white
        }
        return .white
    }
    
    var body: some View {
        Button(action: action) {
            Text(option)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected && !showFeedback ? Color.purple : Color.clear, lineWidth: 3)
                )
        }
        .disabled(showFeedback)
        .padding(.horizontal)
    }
}
