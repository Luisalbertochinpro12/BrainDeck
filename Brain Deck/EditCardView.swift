import SwiftUI

struct EditCardView: View {
    // Usamos @Binding para que los cambios se guarden directamente en la tarjeta original
    @Binding var card: Flashcard
    
    @Environment(\.dismiss) var dismiss // Para cerrar la vista
    
    var body: some View {
        Form {
            Section("Pregunta") {
                TextEditor(text: $card.question)
                    .frame(height: 100)
            }
            
            Section("Respuesta") {
                TextEditor(text: $card.answer)
                    .frame(height: 100)
            }
        }
        .navigationTitle("Editar Tarjeta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Guardar") {
                    // El cambio ya está guardado automáticamente por el @Binding.
                    // Solo cerramos la vista.
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
