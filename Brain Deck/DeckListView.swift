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
                         EditButton().foregroundColor(.purple)
                    }
                    .padding(.bottom, 5)
                    
                    // MARK: - Lista de Mazos
                    // Usamos ForEach para permitir el .onDelete
                    ForEach($decks) { $deck in
                        DeckRowView(deck: $deck)
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
        .onChange(of: decks) { // <-- Sintaxis moderna: no necesita parámetros si solo llama a una función
            saveDecks()
        }
    }
}

// MARK: - Vistas Auxiliares

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
                
                // Asumiendo que el botón pencil llevará a CardManagerView
                // Nota: Asegúrate de que CardManagerView exista o coméntalo si no lo has creado.
                // Si CardManagerView no existe, el código fallará al compilar.
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
                        // El .onChange en DeckListView guardará automáticamente
                    }
                    .disabled(newDeckName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

