import SwiftUI
import EventKit

struct Task: Identifiable {
    let id = UUID()
    var name: String
    var completed: Bool = false
    var dueDate: Date
}

struct ContentView: View {
    @State private var newTask: String = ""
    @State private var tasks: [Task] = []
    @State private var showSettings: Bool = false
    @State private var selectedDayIndex = 0
    private let days: [String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let eventStore = EKEventStore()

    var body: some View {
        NavigationView {
            VStack {
                Text(currentDate())
                    .font(.headline)
                    .padding()
                
                Picker(selection: $selectedDayIndex, label: Text("Day")) {
                    ForEach(0..<days.count, id: \.self) {
                        Text(self.days[$0])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if filteredTasks(for: selectedDayIndex).isEmpty {
                    Spacer()
                    VStack {
                        Text("Congratulations, all your tasks are complete!")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .padding()
                        
                        Text("Enjoy your screen time!")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTasks(for: selectedDayIndex)) { task in
                            TaskRow(task: task, onDelete: { deleteTask(task) })
                                .font(.title)
                        }
                    }
                    .cornerRadius(10)
                    .padding()
                }
                
                TextField("Add a new task", text: $newTask, onCommit: addTask)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.gray.opacity(0.2))
                    .font(.title)
                    .padding()
                
                Button(action: {
                    addEventToCalendar()
                }) {
                    Text("Add Event to Calendar")
                }
                .padding()
            }
            .navigationTitle("To-Do List")
        }
        .onAppear {
            requestCalendarAccess()
        }
    }

    func addTask() {
        if !newTask.isEmpty {
            let dayOffset = selectedDayIndex
            let dueDate = Calendar.current.date(bySetting: .weekday, value: dayOffset + 1, of: Date()) ?? Date()
            let task = Task(name: newTask, dueDate: dueDate)
            tasks.append(task)
            newTask = ""
        }
    }

    func deleteTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
    }
    
    func currentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    func filteredTasks(for dayIndex: Int) -> [Task] {
        let targetDate = Calendar.current.date(bySetting: .weekday, value: dayIndex + 1, of: Date()) ?? Date()
        return tasks.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: targetDate) }
    }
    
    func addEventToCalendar() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "My Event"
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(3600) // 1 hour duration

        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            print("Event saved to calendar")
        } catch {
            print("Error saving event to calendar: \(error.localizedDescription)")
        }
    }

    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                print("Calendar access granted")
            } else {
                print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

struct TaskRow: View {
    var task: Task
    var onDelete: () -> Void
    
    var body: some View {
        if !task.completed {
            HStack {
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "square")
                        .foregroundColor(.black)
                }
                
                Text(task.name)
                    .strikethrough(task.completed)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}