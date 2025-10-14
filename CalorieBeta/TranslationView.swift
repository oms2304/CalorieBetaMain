import SwiftUI
import Translation

@available(iOS 17.4, *)
struct TranslationView: View {
    var text: String
    @State private var showingTranslation = false
    
    var body: some View {
        VStack {
            Text("Identified Text")
                .font(.subheadline.bold())
                .textCase(.uppercase)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
            
            Text(text)
                .frame(maxWidth: .infinity, maxHeight: 50, alignment: .topLeading)
                .padding()
                .background(Color(white: 0.9))
            // Translation framework view modifier, presents a sheet with the translation process inside
                .translationPresentation(isPresented: $showingTranslation, text: text)
            
            Button {
                showingTranslation = true
            } label: {
                Text("Translate")
            }
        }
    }
}

@available(iOS 17.4, *)
#Preview {
    TranslationView(text: "Caution, falling rocks")
}

