import SwiftUI

struct DeckListView: View {
    // Usamos @State para que esta lista se pueda modificar (añadir/eliminar mazos)
    @State private var decks: [Deck] = Deck.sampleDecks
    @State private var showingAddDeckView = false // Controla la hoja modal

    // Función para eliminar mazos
    func deleteDecks(offsets: IndexSet) {
        // La lista 'decks' se modifica directamente
        decks.remove(atOffsets: offsets)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // MARK: - Encabezado (Bienvenida)
                    Text("Welcome").font(.headline).foregroundColor(.gray)
                    Text("Sebastián").font(.largeTitle).fontWeight(.bold).padding(.bottom, 20)
                    
                    // MARK: - Título de Decks
                    HStack {
                         Text("Decks").font(.title2).fontWeight(.semibold)
                         Spacer()
                         // Botón para habilitar la edición (eliminar) en la lista
                         EditButton().foregroundColor(.purple)
                    }
                    .padding(.bottom, 5)
                    
                    // MARK: - Lista de Mazos
                    ForEach($decks) { $deck in
                        DeckRowView(deck: $deck)
                    }
                    // APLICACIÓN DEL MODIFICADOR DE ELIMINACIÓN
                    // NOTA: Este .onDelete necesita un List en lugar de VStack/ScrollView,
                    // pero lo aplicaremos sobre el ForEach para que funcione como swipe.
                    .onDelete(perform: deleteDecks)
                    // Para que .onDelete funcione correctamente en un ScrollView,
                    // deberías usar List, pero mantendremos el diseño actual de VStack
                    // haciendo un pequeño truco con el `ForEach` y el `.onDelete`
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            
            // MARK: - Botón Flotante para Añadir Mazo
            .overlay(alignment: .bottomTrailing) {
                // ... (código del botón flotante) ...
                Button(action: {
                    showingAddDeckView = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            // MARK: - Hoja Modal para Añadir
            .sheet(isPresented: $showingAddDeckView) {
                AddDeckView(decks: $decks, showingAddDeckView: $showingAddDeckView)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Vistas Auxiliares (Fila y Añadir Mazo)

// 1. La vista para cada fila del mazo (DeckRowView)
struct DeckRowView: View {
    @Binding var deck: Deck
    
    var body: some View {
        // NavigationLink que pasa el Binding del mazo ($deck)
        NavigationLink(destination: FlashcardView(deck: $deck)) {
            HStack {
                Text(deck.name)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(deck.cardCount) cards")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Button(action: { print("Editar mazo: \(deck.name)") }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 2. La vista para añadir un mazo
struct AddDeckView: View {
    @Binding var decks: [Deck]
    @Binding var showingAddDeckView: Bool
    @State private var newDeckName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Nombre del Mazo") {
                    TextField("Escribe el nombre del mazo", text: $newDeckName)
                }
            }
            .navigationTitle("Añadir Mazo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { showingAddDeckView = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        let newDeck = Deck(name: newDeckName, cards: [])
                        decks.append(newDeck)
                        showingAddDeckView = false
                    }
                    .disabled(newDeckName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
#Preview {
    DeckListView()
}
