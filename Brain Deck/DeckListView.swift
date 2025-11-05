import SwiftUI

// NOTA IMPORTANTE: Se ASUME que el Helper de FileManager está en un archivo llamado
// PersistenceHelper.swift y que está incluido en el target de esta App.

struct DeckListView: View {
    // Usaremos un array vacío que se llenará con la función loadDecks()
    @State private var decks: [Deck] = []
    @State private var showingAddDeckView = false

    // Función para eliminar mazos
    func deleteDecks(offsets: IndexSet) {
        decks.remove(atOffsets: offsets)
        // El .onChange se encargará de guardar.
    }

    // Función para guardar los mazos
    func saveDecks() {
        // Usa la propiedad compartida definida en PersistenceHelper.swift
        guard let url = FileManager.sharedStoreURL else {
            print("Error: URL de App Group no disponible para guardar.")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(decks)
            try data.write(to: url, options: .atomic)
            print("Mazos guardados en App Group: \(decks.count)")
        } catch {
            print("Error al guardar los mazos: \(error.localizedDescription)")
        }
    }
    
    // Función para cargar los mazos
    func loadDecks() {
        // Usa la propiedad compartida definida en PersistenceHelper.swift
        guard let url = FileManager.sharedStoreURL else {
            // Si no hay URL de App Group, cargamos solo los datos de ejemplo (falla de seguridad)
            decks = Deck.sampleDecks
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            decks = try JSONDecoder().decode([Deck].self, from: data)
            print("Mazos cargados desde App Group: \(decks.count)")
        } catch {
            print("No se encontraron datos guardados en App Group. Cargando datos de ejemplo.")
            decks = Deck.sampleDecks
            saveDecks() // Guarda los datos de ejemplo en la ubicación del App Group
        }
    }

    // Propiedad calculada para ordenar los mazos (los pendientes primero)
    var sortedDecks: [Deck] {
        return decks.sorted { deckA, deckB in
            let today = Date()
            
            let countA = deckA.cards.filter { $0.nextReviewDate <= today }.count
            let countB = deckB.cards.filter { $0.nextReviewDate <= today }.count
            
            // Ordenar de mayor a menor número de tarjetas pendientes
            return countA > countB
        }
    }


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    

                    
                    // MARK: - Título de Decks
                    HStack {
                        Text("Decks").font(.title2).fontWeight(.semibold)
                        Spacer()
                        EditButton().foregroundColor(.purple)
                    }
                    .padding(.bottom, 5)
                    
                    // MARK: - Lista de Mazos
                    // Usamos el array original ($decks) y buscamos el binding por ID
                    ForEach(sortedDecks, id: \.id) { deck in
                        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
                            DeckRowView(deck: $decks[index])
                        }
                    }
                    .onDelete(perform: deleteDecks)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            
            // MARK: - Botón Flotante para Añadir Mazo
            .overlay(alignment: .bottomTrailing) {
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
        // 2. CARGAR AL INICIO Y GUARDAR CON CADA CAMBIO
        .onAppear(perform: loadDecks)
        .onChange(of: decks) {
            saveDecks()
        }
    }
}

// MARK: - Vistas Auxiliares

// 1. La vista para cada fila del mazo (DeckRowView) - ¡CORREGIDA Y COMPLETA!
struct DeckRowView: View {
    @Binding var deck: Deck
    // ¡CRÍTICO!: Esta variable de estado faltaba
    @State private var showingQuizView = false
    
    // Función auxiliar: Devuelve el número de tarjetas pendientes de repaso
    var cardsDueCount: Int {
        let today = Date()
        return deck.cards.filter { card in
            // Compara la fecha de revisión con hoy. Si la fecha de revisión es menor o igual, está vencida.
            card.nextReviewDate <= today
        }.count
    }
    
    // Color para destacar las tarjetas pendientes
    var badgeColor: Color {
        return cardsDueCount > 0 ? .red : .green
    }
    
    var body: some View {
        // NavigationLink que pasa el Binding del mazo ($deck)
        // Este es el link para ir al modo de repaso de tarjetas
        NavigationLink(destination: FlashcardView(deck: $deck)) {
            HStack {
                Text(deck.name)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                // MARK: - Tarjetas Pendientes (Muestra cuántas hay que repasar)
                HStack(spacing: 4) {
                    Image(systemName: cardsDueCount > 0 ? "clock.fill" : "checkmark.circle.fill")
                        .foregroundColor(badgeColor)
                    
                    Text("\(cardsDueCount) Due") // Muestra el número de tarjetas pendientes
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(badgeColor)
                    
                    Text("/ \(deck.cardCount) total") // Muestra el total
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 10)
                
                // MARK: - Botón para INICIAR QUIZ (¡AQUÍ ESTÁ!)
                Button(action: {
                    if deck.cards.count >= 4 {
                        showingQuizView = true // Abre la hoja modal
                    } else {
                        // Podrías poner una alerta aquí si quieres
                        print("Faltan cartas para el quiz")
                    }
                }) {
                    Image(systemName: "questionmark.circle.fill")
                        // Desactivar y oscurecer si no hay suficientes tarjetas
                        .foregroundColor(deck.cards.count >= 4 ? .yellow : .gray)
                }
                // CRÍTICO: Usar PlainButtonStyle es importante dentro de un NavigationLink
                .buttonStyle(PlainButtonStyle())
                .disabled(deck.cards.count < 4)
                
                // Botón pencil lleva a CardManagerView
                NavigationLink(destination: CardManagerView(deck: $deck)) {
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

        // HOJA MODAL para el Quiz (¡ESTO TAMBIÉN FALTABA!)
        .sheet(isPresented: $showingQuizView) {
            NavigationView {
                QuizView(deck: $deck)
            }
        }
    }
}

// 2. La vista para añadir un mazo (AddDeckView)
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
                        // El .onChange en DeckListView guardará automáticamente
                    }
                    .disabled(newDeckName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
