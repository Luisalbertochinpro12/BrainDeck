import SwiftUI

struct FlashcardView: View {
    @Binding var deck: Deck
    
    @State private var currentCardIndex: Int = 0
    @State private var showAnswer: Bool = false
    
    // Almacena solo las tarjetas que están listas para ser estudiadas HOY
    @State private var reviewCards: [Flashcard] = []
    
    // Propiedad calculada para obtener la tarjeta actual
    var currentCard: Flashcard? {
        reviewCards[safe: currentCardIndex]
    }
    
    // Función central para generar el nuevo intervalo de revisión
    func calculateNextReviewDate(for mastery: Int) -> Date {
        let now = Date()
        var interval: TimeInterval = 0
        
        // Elige el intervalo y agrega aleatoriedad para evitar 'avalanchas' de tarjetas
        switch mastery {
        case 1: // Difícil: 30 minutos a 1 hora
            let minutes = Double.random(in: 30...60)
            interval = minutes * 60
        case 2: // Lo sé: 12 a 18 horas
            let hours = Double.random(in: 12...18)
            interval = hours * 3600
        case 3: // Fácil (o Mazo Nuevo): 1 a 2 días
            let days = Double.random(in: 1...2)
            interval = days * 86400
        default:
            interval = 0
        }
        
        return now.addingTimeInterval(interval)
    }
    
    // Función para manejar la calificación y pasar a la siguiente tarjeta
    func rateCard(mastery: Int) {
        guard let currentCard = currentCard else { return }

        // 1. Calculamos la nueva fecha de revisión
        let newReviewDate = calculateNextReviewDate(for: mastery)

        // 2. Encontramos el índice de esa tarjeta en el array ORIGINAL (deck.cards) usando el ID.
        if let originalIndex = deck.cards.firstIndex(where: { $0.id == currentCard.id }) {
            
            // 3. Actualizamos el masteryLevel y la fecha en el array ORIGINAL (persistencia)
            deck.cards[originalIndex].masteryLevel = mastery
            deck.cards[originalIndex].nextReviewDate = newReviewDate
            
            // 4. Movemos la tarjeta actual (reviewCards[currentCardIndex])
            // Ya fue calificada, así que la removemos del lote de estudio de hoy.
            reviewCards.remove(at: currentCardIndex)

            // 5. Ajustamos el índice si la eliminación causó que el índice actual estuviera fuera de límites
            if currentCardIndex >= reviewCards.count && reviewCards.count > 0 {
                currentCardIndex = reviewCards.count - 1
            }
            
            // 6. Si quedan tarjetas, reseteamos el estado de visualización
            if reviewCards.count > 0 {
                showAnswer = false
            } else {
                print("Fin del lote de estudio de hoy!")
            }
        }
    }
    
    // Función para navegar manualmente (solo se usa en los botones de flecha)
    func navigateCard(direction: Int) {
        // Aseguramos que no salgamos de los límites del arreglo
        let newIndex = currentCardIndex + direction
        if newIndex >= 0 && newIndex < reviewCards.count {
            currentCardIndex = newIndex
            showAnswer = false // Oculta la respuesta al cambiar de tarjeta
        }
    }
    
    // Función para construir el array de tarjetas que SÍ toca estudiar hoy
    func prepareCardsForReview() {
        let now = Date()
        
        // Filtramos solo las tarjetas cuya fecha de revisión es HOY o anterior
        reviewCards = deck.cards
            .filter { $0.nextReviewDate <= now }
            
        // Ordenamos las tarjetas: ¡Las más difíciles/viejas primero!
        // Prioridad: 1 (Difícil) > 2 (Lo sé) > 0 (Nuevo/No calificado)
        reviewCards.sort { card1, card2 in
            // 1. Priorizamos las que tienen menor nivel de dominio (más difíciles/nuevas)
            if card1.masteryLevel != card2.masteryLevel {
                return card1.masteryLevel < card2.masteryLevel
            }
            // 2. Si el nivel es el mismo, priorizamos la que lleva más tiempo sin revisar
            return card1.nextReviewDate < card2.nextReviewDate
        }

        currentCardIndex = 0
    }


    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                if let card = currentCard {
                    
                    // MARK: - La Tarjeta con Animación de Volteo
                    FlashcardFlipView(card: card, showAnswer: showAnswer)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showAnswer.toggle()
                            }
                        }
                    
                    // MARK: - Controles de Calificación (Solo visibles con la respuesta)
                    if showAnswer {
                        HStack(spacing: 20) {
                            Button("Difícil 🤯") { rateCard(mastery: 1) }
                            .buttonStyle(RatingButtonStyle(color: .red))
                            
                            // Nivel intermedio (Lo sé)
                            Button("Lo sé 😉") { rateCard(mastery: 2) }
                            .buttonStyle(RatingButtonStyle(color: .green))

                            // Nivel Fácil (o Nueva)
                            Button("Fácil 😇") { rateCard(mastery: 3) }
                            .buttonStyle(RatingButtonStyle(color: .purple))
                        }
                        .padding(.top, 30)
                    }
                    
                    // MARK: - Controles de Navegación (Flechas)
                    HStack {
                        Button(action: { navigateCard(direction: -1) }) {
                            Image(systemName: "arrow.left.circle.fill")
                        }
                        .disabled(currentCardIndex == 0)
                        
                        Spacer()
                        
                        Text("\(currentCardIndex + 1) / \(reviewCards.count)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { navigateCard(direction: 1) }) {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .disabled(currentCardIndex == reviewCards.count - 1)
                    }
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding(.top, showAnswer ? 10 : 40)
                    .padding(.horizontal, 60)
                } else {
                    // Mensaje cuando no hay tarjetas para revisar hoy
                    Text(deck.cardCount > 0 ? "¡Excelente! No hay tarjetas pendientes para hoy." : "Este mazo está vacío.")
                        .foregroundColor(.white)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(40)
                }
            }
        }
        .navigationTitle(deck.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CardManagerView(deck: $deck)) {
                    Text("Gestionar")
                        .foregroundColor(.purple)
                }
            }
        }
        // LLAMADA CLAVE: Prepara las tarjetas al cargar la vista
        .onAppear(perform: prepareCardsForReview)
        .preferredColorScheme(.dark)
    }
}

// MARK: - ESTILO DE BOTÓN PERSONALIZADO (AÑADIDO UN TERCER BOTÓN)
struct RatingButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - VISTAS DE ANIMACIÓN Y CARA (SIN CAMBIOS)

struct FlashcardFlipView: View {
    // ... (Tu código de FlashcardFlipView y CardFace permanece aquí)
    let card: Flashcard
    let showAnswer: Bool
    var rotationAngle: Double { showAnswer ? 180 : 0 }
    
    var body: some View {
        ZStack {
            CardFace(text: card.question, isFront: true)
                .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                .opacity(showAnswer ? 0.0 : 1.0)
            
            CardFace(text: card.answer, isFront: false)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showAnswer ? 1.0 : 0.0)
        }
        .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0))
    }
}

struct CardFace: View {
    let text: String
    let isFront: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding()
            Spacer()
        }
        .frame(width: 300, height: 450)
        .background(isFront ? Color.white : Color.yellow.opacity(0.9))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - Extensión de Seguridad para Arreglos (SIN CAMBIOS)
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

