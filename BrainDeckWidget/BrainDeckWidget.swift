import WidgetKit
import SwiftUI

// CORRECCIÓN 1: Definición del Helper de persistencia dentro del archivo del Widget
// para asegurar que lo encuentre.
extension FileManager {
    static var sharedStoreURL: URL? {
        // ¡Verifica que el nombre del grupo sea correcto!
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.taam.braindeck")?
             .appendingPathComponent("decks.json")
    }
}

// MARK: - 1. TimelineEntry (El modelo de datos para el Widget)
struct SimpleEntry: TimelineEntry {
    let date: Date
    let nextCard: Flashcard?
    let deckName: String
}

// MARK: - 2. Provider (Lógica de Datos y Tiempos)
struct Provider: TimelineProvider {
    
    // Función de carga de datos que AHORA USA EL APP GROUP
    private func loadDecks() -> [Deck] {
        // 1. Obtenemos la URL del App Group
        guard let dataFileUrl = FileManager.sharedStoreURL else {
            print("Error: No se pudo obtener la URL del App Group.")
            return Deck.sampleDecks
        }
        
        do {
            let data = try Data(contentsOf: dataFileUrl)
            let decks = try JSONDecoder().decode([Deck].self, from: data)
            return decks
        } catch {
            // Si hay error, devuelve un mazo de ejemplo para que el widget no esté vacío.
            return Deck.sampleDecks
        }
    }
    
    // Función para obtener la próxima tarjeta a revisar (sin cambios en la lógica)
    private func getNextReviewCard(from decks: [Deck]) -> (Flashcard?, String) {
        let now = Date()
        
        // 1. Aplanamos todas las tarjetas de todos los mazos en un solo array.
        let allCards = decks.flatMap { deck in
            deck.cards.map { card in (card: card, deckName: deck.name) }
        }
        
        // 2. Filtramos solo las tarjetas que deben revisarse HOY (vencidas).
        let reviewCandidates = allCards
            .filter { $0.card.nextReviewDate <= now }
            .sorted { $0.card.nextReviewDate < $1.card.nextReviewDate } // La más antigua primero

        // 3. Devolvemos la tarjeta más antigua si existe.
        if let next = reviewCandidates.first {
            return (next.card, next.deckName)
        }
        
        // 4. Si no hay nada que revisar, devolvemos nil.
        return (nil, "")
    }
    
    // Placeholder y Snapshot (sin cambios)
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            nextCard: Flashcard(question: "¡Próximo Flashcard!", answer: "..."),
            deckName: "Brain Deck"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let decks = loadDecks()
        let (card, deckName) = getNextReviewCard(from: decks)
        let entry = SimpleEntry(date: Date(), nextCard: card, deckName: card == nil ? "Sin Pendientes" : deckName)
        completion(entry)
    }

    // Define la línea de tiempo (sin cambios)
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let decks = loadDecks()
        let (card, deckName) = getNextReviewCard(from: decks)
        
        let currentDate = Date()
        var entries: [SimpleEntry] = []
        
        let entry = SimpleEntry(date: currentDate, nextCard: card, deckName: card == nil ? "Sin Pendientes" : deckName)
        entries.append(entry)
        
        // Programa la próxima actualización para dentro de 30 minutos
        let nextUpdate = currentDate.addingTimeInterval(30 * 60)

        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 3. Vista del Widget (User Interface)
struct BrainDeckWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            if let card = entry.nextCard {
                VStack(alignment: .leading) {
                    Text(entry.deckName)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(card.question)
                        .font(family == .systemSmall ? .subheadline : .title3)
                        .fontWeight(.bold)
                        .lineLimit(family == .systemSmall ? 3 : 2)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 2)

                    Spacer()
                    
                    Text("Revisar Ahora")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(5)
                }
                .padding(family == .systemSmall ? 10 : 16)
                .containerBackground(.black, for: .widget) // iOS 17+
                
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("¡Todo al día!")
                        .font(.headline)
                    Text("Regresa más tarde para repasar.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                .padding(16)
                .containerBackground(.black, for: .widget) // iOS 17+
            }
        }
    }
}

// MARK: - 4. Definición del Widget
@main
struct BrainDeckWidget: Widget {
    let kind: String = "BrainDeckWidget"

    var body: some WidgetConfiguration {
        // CORRECCIÓN 2: El argumento 'kind' debe ir antes que 'provider'
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BrainDeckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Próxima Revisión")
        .description("Muestra la tarjeta de estudio que debes revisar ahora.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
