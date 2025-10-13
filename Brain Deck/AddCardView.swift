import SwiftUI

struct AddCardView: View {
    // Usamos @Binding para añadir la nueva tarjeta al mazo original
    @Binding var deck: Deck
    @Binding var showingAddCardSheet: Bool
    
    @State private var question: String = ""
    @State private var answer: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Pregunta (Frente de la tarjeta)") {
                    TextEditor(text: $question) // Usamos TextEditor para texto largo
                        .frame(height: 100)
                }
                
                Section("Respuesta (Reverso de la tarjeta)") {
                    TextEditor(text: $answer)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Añadir Tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { showingAddCardSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        let newCard = Flashcard(question: question, answer: answer)
                        deck.cards.append(newCard) // ¡CREAR!
                        showingAddCardSheet = false
                    }
                    .disabled(question.isEmpty || answer.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
