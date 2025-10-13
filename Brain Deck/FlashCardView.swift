import SwiftUI

struct FlashcardView: View {
    // @Binding es crucial para que los cambios se guarden en el mazo original.
    @Binding var deck: Deck
    
    // @State para manejar la tarjeta actual y si estamos viendo la respuesta
    @State private var currentCardIndex: Int = 0
    @State private var showAnswer: Bool = false
    
    // Función para manejar la calificación y pasar a la siguiente tarjeta
    func rateCard(mastery: Int) {
        // La corrección: accedemos a deck.cards (el valor real) y luego encontramos el índice.
        // Usamos el ID de la tarjeta actual para asegurar que encontramos la correcta en el array.
        guard let currentCardId = deck.cards[safe: currentCardIndex]?.id else { return }

        // 1. Encontramos el índice de la tarjeta actual en el arreglo del mazo.
        if let cardIndex = deck.cards.firstIndex(where: { $0.id == currentCardId }) {
            // 2. Actualizamos el masteryLevel de esa tarjeta.
            // Aquí NO se usa el $, porque deck.cards ya es el valor mutable gracias a @Binding
            deck.cards[cardIndex].masteryLevel = mastery
            
            // 3. Pasamos a la siguiente tarjeta
            if currentCardIndex < deck.cardCount - 1 {
                navigateCard(direction: 1)
            } else {
                print("Fin del mazo!")
            }
        }
    }
    
    // Función para cambiar de tarjeta
    func navigateCard(direction: Int) {
        currentCardIndex += direction
        showAnswer = false // Siempre oculta la respuesta al cambiar de tarjeta
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                if let card = deck.cards[safe: currentCardIndex] {
                    
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
                            Button("Difícil 🤯") {
                                rateCard(mastery: 1)
                            }
                            .buttonStyle(RatingButtonStyle(color: .red))
                            
                            Button("Lo sé 😉") {
                                rateCard(mastery: 2)
                            }
                            .buttonStyle(RatingButtonStyle(color: .green))
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
                        
                        Text("\(currentCardIndex + 1) / \(deck.cardCount)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { navigateCard(direction: 1) }) {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .disabled(currentCardIndex == deck.cardCount - 1)
                    }
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding(.top, showAnswer ? 10 : 40)
                    .padding(.horizontal, 60)
                } else {
                    Text("¡Este mazo no tiene tarjetas!").foregroundColor(.white).padding()
                }
            }
        }
        .navigationTitle(deck.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Aquí se pasa $deck (el Binding) a CardManagerView, que lo espera.
                NavigationLink(destination: CardManagerView(deck: $deck)) {
                    Text("Gestionar")
                        .foregroundColor(.purple)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ESTILO DE BOTÓN PERSONALIZADO
struct RatingButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - VISTAS DE ANIMACIÓN Y CARA
struct FlashcardFlipView: View {
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

// MARK: - Extensión de Seguridad para Arreglos
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
struct FlashcardView_Previews: PreviewProvider {
    @State static var sampleDeck = Deck.sampleDeck
    
    static var previews: some View {
        NavigationView {
            FlashcardView(deck: $sampleDeck)
        }
        .preferredColorScheme(.dark)
    }
}
