// Task3ViewController.swift
// Copyright © RoadMap. All rights reserved.

import UIKit

// Задание 3.
// Задача 1 - вариант с актором
/// Экран входа в приложение
final class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWithActor()
    }

    func loadWithActor() {
        let phrasesService = PhrasesServiceActor()

        for element in 0 ..< 10 {
            Task {
                await phrasesService.addPhrase("Phrase \(element)")
            }

            // Даем потокам время на завершение работы
            Thread.sleep(forTimeInterval: 1)

            // Выводим результат
            Task {
                await print(phrasesService.phrases)
            }
        }
    }
}

/// PhrasesServiceActor
actor PhrasesServiceActor {
    var phrases: [String] = []

    func addPhrase(_ phrase: String) {
        phrases.append(phrase)
    }
}

// Задача 1 - вариант с семафором
/// SemaphoreViewController
final class SemaphoreViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let phrasesService = PhrasesService()
        let semaphore = DispatchSemaphore(value: 1)

        DispatchQueue.global().async {
            for int in 0 ... 10 {
                print(Thread.current)
                semaphore.wait()
                phrasesService.addPhrase("Phrase \(int)")
                semaphore.signal()
            }
        }

        // Даем потокам время на завершение работы
        Thread.sleep(forTimeInterval: 1)

        // Выводим результат

        semaphore.wait()
        print(phrasesService.phrases)
        semaphore.signal()
    }
}

/// PhrasesService
class PhrasesService {
    var phrases: [String] = []

    func addPhrase(_ phrase: String) {
        phrases.append(phrase)
    }
}

// Задача 2 - печатать все посты одновременно в главном потоке
final class AsyncWorkerController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let asyncWorker = AsyncWorker()

        asyncWorker.doJobs(postNumbers: 1, 2, 3, 4, 5) { posts in
            print(Thread.current)
            print(posts.map(\.id))
        }
    }
}

/// AsyncWorker
class AsyncWorker {
    func doJobs(postNumbers: Int..., completion: @escaping ([Post]) -> Void) {
        var posts: [Post] = []

        let group = DispatchGroup()

        for element in postNumbers {
            // swiftlint: disable force_unwrapping
            group.enter()
            URLSession.shared
                .dataTask(with: URLRequest(
                    url: URL(string: "https://jsonplaceholder.typicode.com/todos/\(element)")!
                )) { data, _, _ in
                    // swiftlint: enable force_unwrapping
                    guard let data = data else {
                        return
                    }
                    if let post = try? JSONDecoder().decode(Post.self, from: data) {
                        posts.append(post)
                    }
                    group.leave()
                }
                .resume()
        }

        // group.wait() // у Димы, выяснить, зачем
        group.notify(queue: .main) {
            completion(posts)
        }
    }
}

/// Post
struct Post: Codable {
    var userId: Int
    var id: Int
    var title: String
    var completed: Bool
}

// Задача 3.1
// Проблема - дедлок
final class DeadLockController: UIViewController {
    let serialQueue = DispatchQueue(label: "com.example.myQueue", attributes: .concurrent)

    override func viewDidLoad() {
        super.viewDidLoad()

        serialQueue.async {
            self.serialQueue.sync {
                print("This will never be printed.")
            }
        }
    }
}

// Задача 3.2
// Проблема - состояние гонки
final class RaceConditionController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let lock = NSLock()

        var sharedResource = 0

        DispatchQueue.global(qos: .background).async {
            for _ in 1 ... 100 {
                lock.lock()
                sharedResource += 1
                lock.unlock()
            }
        }

        DispatchQueue.global(qos: .background).async {
            for _ in 1 ... 100 {
                lock.lock()
                sharedResource += 1
                lock.unlock()
            }
        }
    }
}

// Задача 3.3
// Проблема - ливлок + дата рейс (в процессе решения появлялся)
final class LivelockViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        var firstPerson = FirstPerson()
        var secondPerson = SecondPerson()

        let thread1 = Thread {
            firstPerson.walkPast(with: secondPerson)
            print(Thread.current)
        }

        thread1.start()

        let thread2 = Thread {
            secondPerson.walkPast(with: firstPerson)
            print(Thread.current)
        }

        thread2.start()
    }
}

final class FirstPerson {
    var isDifferentDirections = false

    func walkPast(with person: SecondPerson) {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                while !person.isDifferentDirections {
                    print("FirstPerson не может обойти SecondPerson")
                    sleep(1)
                }
            }
        }

        DispatchQueue.global().async {
            self.isDifferentDirections.toggle()
            print("FirstPerson смог пройти прямо")
            // semaphore.signal()
        }
    }
}

final class SecondPerson {
    var isDifferentDirections = false

    func walkPast(with person: FirstPerson) {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                while !person.isDifferentDirections {
                    print("SecondPerson не может обойти FirstPerson")
                    sleep(1)
                }
            }
        }

        DispatchQueue.global().async {
            self.isDifferentDirections = true
            print("SecondPerson смог пройти прямо")
        }
    }
}

// Задача 3.4
// Проблема - ливлок, но это было подписано вроде
final class RecipeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global().async {
            self.thread1()
        }

        DispatchQueue.global().async {
            self.thread2()
        }
    }

    let resourceASemaphore = DispatchSemaphore(value: 2)
    let resourceBSemaphore = DispatchSemaphore(value: 1)

    func thread1() {
        print("Поток 1 пытается захватить Ресурс A")
        resourceASemaphore.wait() // Захват Ресурса A

        print("Поток 1 захватил Ресурс A и пытается захватить Ресурс B")
        Thread.sleep(forTimeInterval: 1) // Имитация работы для демонстрации livelock

        resourceBSemaphore.wait() // Попытка захвата Ресурса B, который уже занят Потоком 2
        print("Поток 1 захватил Ресурс B")

        resourceASemaphore.signal()
        resourceBSemaphore.signal()
    }

    func thread2() {
        print("Поток 2 пытается захватить Ресурс B")
        resourceBSemaphore.wait() // Захват Ресурса B

        print("Поток 2 захватил Ресурс B и пытается захватить Ресурс A")
        Thread.sleep(forTimeInterval: 1) // Имитация работы для демонстрации livelock

        resourceASemaphore.wait() // Попытка захвата Ресурса A, который уже занят Потоком 1
        print("Поток 2 захватил Ресурс A")

        resourceBSemaphore.signal()
        resourceASemaphore.signal()
    }
}

// Задача с удалением 10 элемента
final class ArrayAdditionServiceController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let service = ArrayAdditionService()
        for element in 1 ... 10 {
            service.addElement(element)
        }
        service.cancelAddition()
    }
}

final class ArrayAdditionService {
    private var array: [Int] = []
    private var pendingWorkItems: [DispatchWorkItem] = []

    // Метод для добавления элемента в массив
    func addElement(_ element: Int) {
        // Создаем новую операцию для добавления элемента в массив
        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.array.append(element)
            print("Элемент \(element) успешно добавлен в массив.")
        }

        // Сохраняем новую операцию
        pendingWorkItems.append(newWorkItem)

        // Даем пользователю время для отмены операции
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !newWorkItem.isCancelled {
                newWorkItem.perform()
            }
        }
    }

    // Метод для отмены операции добавления элемента в массив
    func cancelAddition() {
        guard let lastWorkItem = pendingWorkItems.last else {
            print("Нет операций для отмены.")
            return
        }
        lastWorkItem.cancel()
    }
}
