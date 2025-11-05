import SwiftUI

// MARK: - QuizResultsView: Vista Separada de Resultados
struct QuizResultsView: View {
    let score: Int
    let totalQuestions: Int
    
    // Recibe la función de cierre desde QuizView (la que cierra la modal)
    let dismissAction: () -> Void
    
    var percentage: Double {
        totalQuestions > 0 ? Double(score) / Double(totalQuestions) : 0.0
    }
    
    var feedbackMessage: String {
        switch percentage {
        case 0.8...1.0: return "¡Excelente trabajo! ¡Dominio total del mazo! 🎉"
        case 0.5..<0.8: return "Buen resultado. Un poco más de práctica y lo tendrás. 👍"
        default: return "Necesitas repasar estos conceptos. ¡Sigue practicando! 🧐"
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("Resultados Finales")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                Text("\(score) de \(totalQuestions)")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.yellow)
                
                Text("(\(Int(percentage * 100))% de aciertos)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(feedbackMessage)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            
            // MARK: - CORRECCIÓN CLAVE: Botón con Retraso Asíncrono
            Button("Volver a Mazos") {
                // Aplicamos un pequeño retraso para darle tiempo a SwiftUI
                // a completar el ciclo de vida de la vista antes de cerrarla.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    dismissAction()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(40)
        .preferredColorScheme(.dark)
    }
}
