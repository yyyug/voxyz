import SwiftUI

struct PresenterView: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                }
                .padding()
            }

            Spacer()

            ScrollView {
                Text(text)
                    .font(.system(size: AppSettings.shared.fontSize))
                    .padding()
            }

            Spacer()
        }
        .background(Color.black)
        .foregroundColor(.white)
    }
}
