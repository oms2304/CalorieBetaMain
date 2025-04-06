import SwiftUI
import FirebaseFirestore

// This view provides an AI-powered chatbot interface for users to request healthy recipes.
// It integrates with the OpenAI API and persists chat history using UserDefaults.
struct AIChatbotView: View {
    // State variables to manage the chat interface:
    @State private var userMessage = "" // The text input by the user for the chatbot.
    @State private var chatMessages: [ChatMessage] = loadChatHistory() // The list of chat messages, loaded from storage.
    @State private var isLoading = false // Tracks whether a response is being fetched to disable the send button.
    @Binding var selectedTab: Int // Binding to switch tabs (e.g., back to HomeView).

    // The main body of the view, organized in a vertical stack.
    var body: some View {
        VStack {
            // Scrollable area to display the chat history.
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Loops through each message and displays it in a chat bubble.
                    ForEach(chatMessages) { message in
                        ChatBubble(message: message)
                    }
                }
            }
            .padding() // Adds padding around the scroll view.

            // Horizontal stack for the input field and send button.
            HStack {
                TextField("Ask for a healthy recipe...", text: $userMessage) // Input field for user messages.
                    .textFieldStyle(RoundedBorderTextFieldStyle()) // Applies a rounded border style.
                    .padding() // Adds internal padding.
                    .submitLabel(.done) // Sets the keyboard submit button to "Done".
                    .onSubmit {
                        sendMessage() // Triggers message sending when "Done" is pressed.
                    }

                Button(action: sendMessage) { // Button to send the message manually.
                    Image(systemName: "paperplane.fill") // Paper plane icon for sending.
                        .font(.title2) // Larger icon size.
                        .padding() // Adds padding around the icon.
                }
                .disabled(isLoading || userMessage.isEmpty) // Disables the button during loading or if empty.
            }
            .padding() // Adds padding around the input area.

            Button(action: {
                selectedTab = 0 // Switches back to the Home tab.
                hideKeyboard() // Hides the keyboard.
                saveChatHistory() // Saves the current chat history.
            }) {
                Text("Done") // Button to finish the chat.
                    .foregroundColor(.blue) // Blue text color.
                    .padding() // Adds internal padding.
                    .background(Color.gray.opacity(0.2)) // Light gray background.
                    .cornerRadius(8) // Rounded corners.
            }
            .padding(.bottom, 10) // Adds bottom padding.
        }
        .navigationTitle("AI Recipe Bot") // Sets the navigation bar title.
        .onTapGesture {
            hideKeyboard() // Hides the keyboard when tapping outside the input.
        }
    }

    // Sends the user's message to the chatbot and appends the response.
    func sendMessage() {
        guard !userMessage.isEmpty else { return } // Exits if the message is empty.

        let userChatMessage = ChatMessage(id: UUID(), text: userMessage, isUser: true) // Creates a user message.
        chatMessages.append(userChatMessage) // Adds the user message to the chat.

        userMessage = "" // Clears the input field.
        isLoading = true // Starts the loading state.

        // Fetches a response from the OpenAI API.
        fetchGPT3Response(for: userChatMessage.text) { aiResponseText in
            let aiChatMessage = ChatMessage(id: UUID(), text: aiResponseText, isUser: false) // Creates an AI response.
            chatMessages.append(aiChatMessage) // Adds the AI response to the chat.
            isLoading = false // Stops the loading state.
        }
    }

    // Fetches a response from the OpenAI GPT-3.5 API based on the user's message.
    func fetchGPT3Response(for message: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")! // API endpoint URL.

        let apiKey = "add_api_key" // API key (should be stored securely in production).

        var request = URLRequest(url: url) // Initializes the HTTP request.
        request.httpMethod = "POST" // Sets the request method to POST.
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // Adds authentication.
        request.addValue("application/json", forHTTPHeaderField: "Content-Type") // Sets the content type.

        // Defines the request body with the model, message, and parameters.
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Specifies the GPT-3.5 model.
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that provides healthy and nutritious recipes."], // System instruction.
                ["role": "user", "content": message] // User’s message.
            ],
            "max_tokens": 1000, // Limits the response length.
            "temperature": 0.7 // Controls randomness (0.7 for balanced responses).
        ]

        // Converts the request body to JSON data.
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Error serializing JSON for GPT-3.5 request.")
            completion("Sorry, something went wrong when preparing the request.")
            return
        }

        request.httpBody = bodyData // Sets the request body.

        print("Sending request to GPT-3.5: \(String(data: bodyData, encoding: .utf8)!)") // Logs the request for debugging.

        // Performs the API request asynchronously.
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling GPT-3.5 API: \(error.localizedDescription)") // Logs any network errors.
                DispatchQueue.main.async {
                    completion("Sorry, I couldn't fetch a recipe at the moment. Please try again.")
                }
                return
            }

            guard let data = data else {
                print("No data returned from GPT-3.5 API") // Logs if no data is received.
                DispatchQueue.main.async {
                    completion("Sorry, no recipe available at the moment.")
                }
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("GPT-3.5 Response: \(responseString)") // Logs the raw response.
            }

            do {
                // Parses the JSON response from the API.
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Parsed JSON: \(json)") // Logs the parsed JSON.

                    // Extracts the response text from the JSON structure.
                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let text = message["content"] as? String {
                        DispatchQueue.main.async {
                            completion(text.trimmingCharacters(in: .whitespacesAndNewlines)) // Returns the cleaned response.
                        }
                    } else {
                        print("Invalid or missing 'choices' in JSON response") // Logs if the response is malformed.
                        DispatchQueue.main.async {
                            completion("Sorry, I couldn't understand that. Try asking again.")
                        }
                    }
                } else {
                    print("Invalid JSON structure") // Logs if JSON parsing fails.
                    DispatchQueue.main.async {
                        completion("Sorry, I couldn't process the response. Try again.")
                    }
                }
            } catch {
                print("Error parsing GPT-3.5 response: \(error.localizedDescription)") // Logs parsing errors.
                DispatchQueue.main.async {
                    completion("Sorry, I couldn't understand that. Please try again.")
                }
            }
        }.resume() // Starts the network task.
    }

    // Hides the keyboard when called (useful for dismissing it manually).
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // Saves the current chat history to UserDefaults, limiting to the last 8 messages.
    private func saveChatHistory() {
        let maxMessages = 8 // Maximum number of messages to retain.
        if chatMessages.count > maxMessages {
            let trimmedMessages = Array(chatMessages.suffix(maxMessages)) // Keeps the last 8 messages.
            UserDefaults.standard.set(try? JSONEncoder().encode(trimmedMessages), forKey: "chatHistory")
        } else {
            UserDefaults.standard.set(try? JSONEncoder().encode(chatMessages), forKey: "chatHistory")
        }
    }
}

// Loads the chat history from UserDefaults when the view initializes.
func loadChatHistory() -> [ChatMessage] {
    if let data = UserDefaults.standard.data(forKey: "chatHistory"), // Retrieves stored data.
       let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
        return messages // Returns the decoded messages if successful.
    }
    return [] // Returns an empty array if no history or decoding fails.
}

// A struct to represent a single chat message, conforming to Identifiable and Codable.
struct ChatMessage: Identifiable, Codable {
    let id: UUID // Unique identifier for each message.
    let text: String // The message content.
    let isUser: Bool // Indicates if the message is from the user or AI.
}

// A view to display a single chat message in a bubble style.
struct ChatBubble: View {
    let message: ChatMessage // The message to display.

    var body: some View {
        HStack {
            if message.isUser {
                Spacer() // Pushes the user message to the right.
            }
            Text(message.text) // Displays the message text.
                .padding() // Adds internal padding.
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2)) // Blue for user, light gray for AI.
                .cornerRadius(12) // Rounded corners for the bubble.
                .foregroundColor(message.isUser ? .white : .black) // White text for user, black for AI.
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading) // Limits width and aligns text.

            if !message.isUser {
                Spacer() // Pushes the AI message to the left.
            }
        }
        .padding(message.isUser ? .leading : .trailing, 40) // Adds extra padding on the opposite side.
    }
}
