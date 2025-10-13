import SwiftUI

// MARK: - 1. Vista Principal de Gestión de Tarjetas
struct CardManagerView: View {
    // Recibimos el mazo como Binding para modificarlo
    @Binding var deck: Deck
    @State private var showingAddCardSheet = false
    
    // Función para eliminar tarjetas
    func deleteCards(offsets: IndexSet) {
        deck.cards.remove(atOffsets: offsets)
        // Nota: El .onChange de DeckListView guarda automáticamente los cambios.
    }

    var body: some View {
        VStack {
            // MARK: - Lista de Tarjetas
            List {
                // ForEach que usa el Binding ($deck.cards) para iterar y permitir .onDelete
                ForEach($deck.cards) { $card in
                    // Navegación para EDITAR una tarjeta
                    // CORRECCIÓN: Sólo pasamos la tarjeta a editar ($card)
                    NavigationLink(destination: EditCardView(card: $card)) {
                        VStack(alignment: .leading) {
                            Text(card.question)
                                .font(.headline)
                                .lineLimit(1)
                            Text("Dominio: \(card.masteryLevel)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteCards)
            }
            .listStyle(.insetGrouped)
            
            // Botón flotante para añadir tarjeta
            Button(action: {
                showingAddCardSheet = true
            }) {
                Text("Añadir Nueva Tarjeta")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .padding([.horizontal, .bottom])
        }
        .navigationTitle("Tarjetas: \(deck.name)")
        
        // MARK: - Hoja Modal para Añadir Tarjeta
        .sheet(isPresented: $showingAddCardSheet) {
            // Pasamos el array de tarjetas para añadir la nueva
            AddCardView(deckCards: $deck.cards)
        }
    }
}

// ----------------------------------------------------------------------

// MARK: - 2. Vista para Añadir Tarjeta (Sheet)
struct AddCardView: View {
    // Binding al array de tarjetas del mazo
    @Binding var deckCards: [Flashcard]
    @Environment(\.dismiss) var dismiss
    
    @State private var question: String = ""
    @State private var answer: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Pregunta") {
                    TextEditor(text: $question)
                        .frame(minHeight: 100)
                }
                
                Section("Respuesta") {
                    TextEditor(text: $answer)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Nueva Tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        let newCard = Flashcard(question: question, answer: answer)
                        deckCards.append(newCard) // Añadir la tarjeta
                        dismiss()
                    }
                    .disabled(question.isEmpty || answer.isEmpty)
                }
            }
        }
    }
}

// ----------------------------------------------------------------------

// MARK: - 3. Vista para Editar Tarjeta (Detail)
struct EditCardView: View {
    // Solo necesitamos el Binding de la tarjeta individual
    @Binding var card: Flashcard
    
    @Environment(\.dismiss) var dismiss
    
    // Simplificado: Usamos los Binding directamente sin @State temporales.
    var body: some View {
        Form {
            Section("Pregunta") {
                // Editamos la propiedad de la tarjeta directamente
                TextEditor(text: $card.question)
                    .frame(minHeight: 100)
            }
            
            Section("Respuesta") {
                // Editamos la propiedad de la tarjeta directamente
                TextEditor(text: $card.answer)
                    .frame(minHeight: 100)
            }
            
            Section("Información de Repetición") {
                Text("Nivel de Dominio: \(card.masteryLevel)")
                Text("Próxima Revisión: \(card.nextReviewDate, style: .date) \(card.nextReviewDate, style: .time)")
            }
        }
        .navigationTitle("Editar Tarjeta")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Guardar") {
                    // Los cambios ya están en 'card' gracias al @Binding.
                    // Solo cerramos la vista.
                    dismiss()
                }
                .disabled(card.question.isEmpty || card.answer.isEmpty)
            }
        }
    }
}
