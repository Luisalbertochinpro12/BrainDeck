import SwiftUI

// NOTA: Usamos @Binding para que cualquier cambio en las tarjetas
// se refleje en la lista original de mazos (DeckListView)
struct CardManagerView: View {
    @Binding var deck: Deck
    
    @State private var showingAddCardSheet = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Usamos List para que las filas tengan la funcionalidad de deslizar (swipe) para eliminar
            List {
                ForEach($deck.cards) { $card in
                    // Usamos NavigationLink para que al tocar la tarjeta se pueda editar.
                    NavigationLink(destination: EditCardView(card: $card)) {
                        VStack(alignment: .leading) {
                            Text(card.question)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(card.answer)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                // Habilidad para deslizar y eliminar la tarjeta
                .onDelete(perform: deleteCards)
            }
            // MODIFICADORES DE LISTA para que se vea bien en el modo oscuro
            .listStyle(.plain)
            .background(Color.black)
        }
        .navigationTitle("\(deck.name) Cards")
        .toolbar {
            // Botón para añadir una nueva tarjeta
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddCardSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.purple)
                }
            }
            // Botón para editar la lista (habilita el botón de eliminar)
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddCardSheet) {
            AddCardView(deck: $deck, showingAddCardSheet: $showingAddCardSheet)
        }
        .preferredColorScheme(.dark)
    }
    
    // Función para eliminar tarjetas
    func deleteCards(offsets: IndexSet) {
        deck.cards.remove(atOffsets: offsets)
    }
}
