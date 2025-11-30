import SwiftUI
import FirebaseAuth


struct AIJournalSheet : View {
    @EnvironmentObject var dailyLogService: DailyLogService
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var showingAddJournalView = false

    private func deleteJournalEntry(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid,
                let allEntries = dailyLogService.currentDailyLog?.journalEntries else { return }
        
        let entriesToDelete = offsets.map { allEntries[$0] }
        
        for entry in entriesToDelete {
            dailyLogService.deleteJournalEntry(for: userID, entry: entry)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let entries = dailyLogService.currentDailyLog?.journalEntries, !entries.isEmpty {
                    List {
                        ForEach(entries) { entry in
                            HStack(spacing: 8) {
                                Text(JournalEmojiMapper.getEmoji(for: entry.category))
                                    .font(.title3)
                                
                                VStack(alignment: .leading) {
                                    Text(entry.text)
                                        .appFont(size: 15, weight: .medium)
                                        .foregroundColor(.textPrimary)
                                        .lineLimit(2)
                                    
                                    Text(entry.category)
                                        .appFont(size: 12)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear) // *** ADDED THIS LINE ***
                            .cornerRadius(20)
                        }
                        .onDelete(perform: deleteJournalEntry)
//                        .listRowSeparator(.hidden)
                    }
//                    .listStyle(.plain)
                    .frame(height: CGFloat(entries.count) * 60)
                    .padding(.top, -5)
                    .background(Color.clear) // This background(Color.clear) is
                    .cornerRadius(20)
                    .padding()
                    
                    Spacer()
                    
                } else {
                    Text("No journal entries for this day.")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .appFont(size: 15)
                        .frame(maxWidth: .infinity)
                        .padding()
                    
                    Spacer()
                }
                
            }
            .navigationTitle("AI Journal")
            
            .navigationBarItems(trailing:
                Button("Add Entry"){
                showingAddJournalView = true
            })
            .navigationBarItems(leading:
                Button("Cancel") {
                    dismiss()
            })
            .appFont(size: 15, weight: .semibold)
            .foregroundColor(.brandPrimary)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.88)
//            .asCard()
//            .background(colorScheme == .dark ? Color.backgroundPrimary : Color.brandPrimary.opacity(0.03))
            .cornerRadius(20)
            .sheet(isPresented: $showingAddJournalView) {
                JournalView()
            }
            
            
        }
    }
}

struct JournalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dailyLogService: DailyLogService
    
    @State private var entryText: String = ""
    @State private var selectedCategory: String = "Recovery"
    let categories = ["Recovery", "Mindfulness", "Flexibility", "Other"]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("How are you feeling?")) {
                        TextEditor(text: $entryText)
                            .frame(height: 150)
                    }
                    
                    Section {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                }
                
                Button(action: saveEntry) {
                    Label("Save to Journal", systemImage: "book.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(entryText.isEmpty)
                .padding()
            }
            
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let newEntry = JournalEntry(
            date: Date(),
            text: entryText,
            category: selectedCategory
        )
        Task {
            await dailyLogService.addJournalEntry(for: userID, entry: newEntry)
        }
        dismiss()
    }
}


#Preview {
   AIJournalSheet()
        .environmentObject(DailyLogService())
}

