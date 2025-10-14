import SwiftUI

@available(iOS 18, *)
struct TextRecognitionView: View {
    let imageResource: ImageResource
    @State private var textRecognizer: TextRecognizer?
        
    var body: some View {
        VStack {
            Image(imageResource)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .task {
                    textRecognizer = await TextRecognizer(imageResource: imageResource)
                }
            Spacer()
            
            TranslationView(text: textRecognizer?.recognizedText ?? "")
        }
        .padding()
        .navigationTitle("Sign Info")
    }
}

@available(iOS 18, *)
#Preview {
    NavigationStack {
        TextRecognitionView(imageResource: .sign1)
            .navigationBarTitleDisplayMode(.inline)
    }
}
