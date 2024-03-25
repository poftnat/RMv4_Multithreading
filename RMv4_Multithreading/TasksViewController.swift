// TasksViewController.swift
// Copyright © RoadMap. All rights reserved.

import UIKit

// ЗАДАЧА 1.
// 1. - Набрать руками и объяснить, почему так распечаталось?
// Исходный код вызывает синхронное выполнение задачи на главном потоке, после того, как все последовательно выполнится
// из viewDidLoad(), будет выполняться задача под DispatchQueue.main.
// 2. - Заменить DispatchQueue.main.async на Task, распечатать и объяснить, что изменилось?
// Ничего не изменилось, работает асинхронно в главном потоке.
final class FirstTaskViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .gray

        print(1)
        Task {
            print(2)
        }
        print(3)
    }
}

// ЗАДАЧА 2.
// Чем этот вариант @MainActor отличается от обычного Task{}?
// Вызов MainActor выполнит задачу на main thread.

// ЗАДАЧА 3.
// Набрать пример руками, заменить DispatchQueue.global().async на Task.detached, объяснить, в чем разница.
// Насколько я понимаю, Task.detached будет всегда выделять задаче новый поток, но очереди DispatchQueue.global() могут
// использовать и главный поток тоже.
// Далее поменять у Task.detached приоритет на priority: .userInitiated

final class ThirdTaskViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Task 1 is finished")

        Task.detached(priority: .userInitiated) {
            for item in 0 ... 10 {
                print(item)
            }
            print("Task 2 is finished")
        }

        print("Task 3 is finished")
    }
}

// ЗАДАЧА 4.
// Попрактикуйтесь, переведите данный код на async/await.

final class FourthTaskViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            let result = await randomD6()
            print(result)
        }
    }

    func randomD6() async -> Int {
        Int.random(in: 1 ... 6)
    }
}

// ЗАДАЧА 5.
// Появилась обычная боевая задача, у вас есть сетевой сервис который легаси его менять не нужно, но все что в
// ViewController должно работать на async/await.
// Измените метод fetchMessagesResult на func fetchMessages() async -> [Message] { и содержимое метода переведите на
// async с помощь withCheckedContinuation.
// P.S меняем только этот метод в пару строчек и вызов его в viewDidLoad тоже в пару строчек.

final class FifthTaskViewController: UIViewController {
    var networkService = NetworkService()

    override func viewDidLoad() {
        super.viewDidLoad()

        Task.init {
            print(await fetchMessagesResult())
        }
    }

    func fetchMessagesResult() async -> [Message] {
        await withCheckedContinuation { continuation in
            networkService.fetchMessages { message in
                continuation.resume(returning: message)
            }
        }
    }
}

/// struct Message
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

/// class NetworkService
class NetworkService {
    func fetchMessages(completion: @escaping ([Message]) -> Void) {
        // swiftlint: disable force_unwrapping
        let url = URL(string: "https://hws.dev/user-messages.json")!
        // swiftlint: enable force_unwrapping
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let messages = try? JSONDecoder().decode([Message].self, from: data) {
                    completion(messages)
                    return
                }
            }

            completion([])
        }
        .resume()
    }
}

// ЗАДАЧА 6.
// А теперь этот же метод обработать через withChecked ThrowingContinuation на случай если messages.isEmpty то
// continuation.resume(throwing: а если не пустой то resume(returning:).

final class SixthTaskViewController: UIViewController {
    var networkService = NetworkService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task.init {
            print(await fetchMessagesResult())
        }
    }
    
    func fetchMessagesResult() async -> [Message] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                networkService.fetchMessages { message in
                    if message.isEmpty {
                        let error = CustomError.emptyMessage
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: message)
                    }
                }
            }
        } catch {
            return []
        }
    }
}

/// CustomError
enum CustomError: Error {
    case emptyMessage
}


// ЗАДАЧА 7.
// Наберите задачу. Разберитесь как работает. Отмените задачу fetchTask.
final class SeventhTaskViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await getAverageTemperature()
        }
    }

    func getAverageTemperature() async {
        let fetchTask = Task { () -> Double in
            // swiftlint: disable force_unwrapping
            let url = URL(string: "https://hws.dev/readings.json")!
            // swiftlint: enable force_unwrapping
            let (data, _) = try await URLSession.shared.data(from: url)
            let readings = try JSONDecoder().decode([Double].self, from: data)
            let sum = readings.reduce(0, +)
            return sum / Double(readings.count)
        }

        fetchTask.cancel()

        do {
            let result = try await fetchTask.value
            print("Average temperature: \(result)")
        } catch {
            print("Failed to get data.")
        }
    }
}

// ЗАДАЧА 8.
// Наберите задачу. Разберитесь, как работает taskGroup.
// Добавить в метод printMessage в group 5 строк "Hello", "My", "Road", "Map", "Group".

final class EightTaskViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await printMessage()
        }
    }

    func printMessage() async {
        let string = await withTaskGroup(of: String.self) { group -> String in
            
            group.addTask {
                "Hello"
            }

            group.addTask {
                "My"
            }

            group.addTask {
                "Road"
            }

            group.addTask {
                "Map"
            }

            group.addTask {
                "Group"
            }

            var collected: [String] = []

            for await value in group {
                collected.append(value)
            }

            return collected.joined(separator: " ")
        }

        print(string)
    }
}
