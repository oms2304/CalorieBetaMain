import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// This view provides a sign-up interface for users to create a new account using email, password,
// username, and confirm password, integrating with Firebase Authentication and Firestore.
struct SignUpView: View {
    // State variables to manage user input and UI state.
    @State private var email = "" // Stores the email input.
    @State private var password = "" // Stores the password input.
    @State private var confirmPassword = "" // Stores the confirm password input.
    @State private var username = "" // Stores the username input.
    @State private var signUpError = "" // Stores any error message to display.
    // Environment variable to control dismissal of the view.
    @Environment(\.presentationMode) var presentationMode

    // The main body of the view, organized in a vertical stack.
    var body: some View {
        VStack(spacing: 0) { // Vertical stack with no spacing between sections.
            // Header with Background Image and Close Button
            ZStack { // Layers the background image, text, and close button.
                // Background Image with Blur and Dark Overlay
                Image("salad") // Placeholder for a background image (must be added to assets).
                    .resizable() // Allows the image to be resized.
                    .scaledToFill() // Fills the frame while maintaining aspect ratio.
                    .clipped() // Clips any overflow.
                    .overlay(Color.black.opacity(0.65)) // Adds a dark overlay for contrast.

                // Text Content Centered Vertically
                VStack(spacing: 10) {
                    Text("Create Your Account!") // Welcome message for sign-up.
                        .font(.largeTitle) // Large, prominent font.
                        .fontWeight(.bold) // Bold text for emphasis.
                        .foregroundColor(.white) // White text for contrast against the dark overlay.
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Centers the text.

                // Close Button in Top-Right Corner
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // Dismisses the view when tapped.
                }) {
                    Image(systemName: "xmark.circle.fill") // Close icon.
                        .font(.title) // Larger font size for visibility.
                        .foregroundColor(.white) // White icon for contrast.
                }
                .position(x: UIScreen.main.bounds.width - 25, y: 60) // Hardcoded position in top-right corner.
            }
            .frame(height: 200) // Fixed height for the header section.

            // Join Now and Form Section
            VStack(spacing: 16) { // Vertical stack with spacing between elements.
                VStack(spacing: 16) {
                    // Username input field using a custom RoundedTextField.
                    RoundedTextField(placeholder: "Username", text: $username)
                    // Email input field using a custom RoundedTextField.
                    RoundedTextField(placeholder: "Email", text: $email, isEmail: true)
                    // Password input field using a custom RoundedSecureField.
                    RoundedSecureField(placeholder: "Password", text: $password)
                    // Confirm password input field using a custom RoundedSecureField.
                    RoundedSecureField(placeholder: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal) // Adds horizontal padding to the input fields.

                // Error Message
                if !signUpError.isEmpty { // Shows error message if present.
                    Text(signUpError) // Displays the error text.
                        .foregroundColor(.red) // Red color for error visibility.
                        .font(.caption) // Smaller font for the error message.
                        .padding(.top, 10) // Adds space above the error message.
                }
                Spacer() // Pushes the button to the bottom of the form section.

                // Submit Button
                Button(action: signUpUser) { // Sign-up button.
                    Text("Join Now") // Button label.
                        .font(.title2) // Slightly larger font for emphasis.
                        .fontWeight(.semibold) // Semibold text for readability.
                        .frame(maxWidth: .infinity) // Expands to full width.
                        .padding() // Adds internal padding.
                        .background(Color.green) // Green background for visibility.
                        .foregroundColor(.black) // Black text for contrast.
                        .cornerRadius(30) // Rounded corners for a modern look.
                }
                .padding(.horizontal) // Adds horizontal padding around the button.
            }
            .padding(.top, 20) // Adds space above the form section.
            .background( // Applies a styled background to the form section.
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30)) // Rounds the top corners.
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Ensures a white background across the entire view.
    }

    // Handles user sign-up using Firebase Authentication and saves user data to Firestore.
    private func signUpUser() {
        guard !username.isEmpty else { // Validates that username is provided.
            signUpError = "Username is required" // Sets error if username is empty.
            return
        }

        guard password == confirmPassword else { // Validates password match.
            signUpError = "Passwords do not match" // Sets error if passwords differ.
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error { // Checks for authentication errors.
                signUpError = error.localizedDescription // Sets the error message to display.
                return
            }

            if let user = authResult?.user { // Ensures a user was created.
                saveUserData(user: user) // Saves user data to Firestore.
            }
        }
    }

    // Saves user data to Firestore, including initial goals and calorie history.
    private func saveUserData(user: FirebaseAuth.User) {
        let db = Firestore.firestore() // Initializes the Firestore database instance.
        let userData: [String: Any] = [ // Prepares user data dictionary.
            "email": user.email ?? "", // Stores the user's email (defaults to empty string if nil).
            "userID": user.uid, // Stores the unique user ID.
            "username": username, // Stores the entered username.
            "goals": [ // Initializes default nutritional goals.
                "calories": 2000, // Default calorie goal.
                "protein": 150, // Default protein goal in grams.
                "fats": 70, // Default fat goal in grams.
                "carbs": 250 // Default carbohydrate goal in grams.
            ],
            "weight": 150.0 // Default weight in pounds (can be updated later).
        ]

        // Saves user data to the "users" collection with the user's UID as the document ID.
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error { // Checks for Firestore write errors.
                print("Error saving user data: \(error.localizedDescription)") // Logs the error.
            } else {
                // Initializes an empty calorie history entry for the user.
                db.collection("users").document(user.uid).collection("calorieHistory").addDocument(data: [
                    "date": Timestamp(date: Date()), // Current date as a timestamp.
                    "calories": 0.0 // Initial calorie value (to be updated with logs).
                ]) { historyError in
                    if let historyError = historyError { // Checks for history write errors.
                        print("Error initializing calorie history: \(historyError.localizedDescription)") // Logs the error.
                    } else {
                        print("Calorie history initialized for user \(user.uid).") // Logs success.
                    }
                }
            }
        }
    }
}

// Custom Shape for Rounded Corners
// Defines a custom shape to create rounded corners for specific edges of a view.
struct CustomCorners: Shape {
    var corners: UIRectCorner // Specifies which corners to round.
    var radius: CGFloat // Radius of the rounded corners.

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, // Defines the rectangle to round.
            byRoundingCorners: corners, // Applies rounding to specified corners.
            cornerRadii: CGSize(width: radius, height: radius) // Sets the radius size.
        )
        return Path(path.cgPath) // Converts to a SwiftUI Path.
    }
}

// Reusable Components
// A custom text field with rounded corners and a border.
struct RoundedTextField: View {
    var placeholder: String // Placeholder text to display.
    @Binding var text: String // Binding to the text value.
    var isEmail: Bool = false // Flag to determine keyboard type.

    var body: some View {
        TextField(placeholder, text: $text) // Standard text field.
            .keyboardType(isEmail ? .emailAddress : .default) // Sets keyboard type based on isEmail.
            .padding() // Adds internal padding.
            .background(Color(.white)) // White background.
            .cornerRadius(30) // Rounds the corners.
            .overlay( // Adds a border.
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.black, lineWidth: 1) // Black border with 1pt width.
            )
    }
}

// A custom secure text field (e.g., for passwords) with rounded corners and a border.
struct RoundedSecureField: View {
    var placeholder: String // Placeholder text to display.
    @Binding var text: String // Binding to the text value.

    var body: some View {
        SecureField(placeholder, text: $text) // Secure text field for passwords.
            .padding() // Adds internal padding.
            .background(Color(.white)) // White background.
            .cornerRadius(30) // Rounds the corners.
            .overlay( // Adds a border.
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.black, lineWidth: 1) // Black border with 1pt width.
            )
    }
}
