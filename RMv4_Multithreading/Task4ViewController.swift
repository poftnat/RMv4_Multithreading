// Task4ViewController.swift
// Copyright © RoadMap. All rights reserved.

import UIKit

// Задание 4.
// Задача 1 Ошибка возникает потому, что тип Пост тоже требуется проверить и промаркировать как sendable. Для
// типов-значений
// дополнительные проверки не требуются.

/// ViewController
class ViewController: UIViewController {
    class Post: @unchecked Sendable {}

    enum State1: Sendable {
        case loading
        case data(String)
    }

    enum State2: Sendable {
        case loading
        case data(Post)
    }
}

// Задача 2
/// RMOperationProtocol
protocol RMOperationProtocol {
    // Приоритеты
    var priority: DispatchQoS.QoSClass { get }
    // Выполняемый блок
    var completionBlockHandler: (() -> ())? { get }
    // Завершена ли операция
    var isFinished: Bool { get }
    // Выполняется ли операция
    var isExecuting: Bool { get }
    // Метод для запуска операции
    func start()
}

/// RMOperation
class RMOperation: RMOperationProtocol {
    var priority: DispatchQoS.QoSClass

    var completionBlockHandler: (() -> ())?

    var isFinished: Bool
    var isExecuting = false

    init() {
        priority = .userInteractive
        isFinished = false
    }

    func start() {
        isExecuting = true
        DispatchQueue.global().async {
            self.completionBlockHandler?()
        }
        
// Димин вариант, нужно отслеживать стопроцентное выполнение операции, чтобы поменять флаг, поэтому ДиспатчГруп
//        let globalQueue = DispatchQueue.global(qos: priority)
//        let group = DispatchGroup()
//        globalQueue.async(group: group) {
//            self.isExecuting = true
//            self.completionBlock?()
//        }
//        group.wait()
//        group.notify(queue: globalQueue) {
//            self.isFinished = true
//        }
    }
}

/// Task4ViewController
final class Task4ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let operationFirst = RMOperation()
        let operationSecond = RMOperation()

        operationFirst.priority = .userInitiated
        operationFirst.completionBlockHandler = {
            for _ in 0 ..< 50 {
                print(2)
            }
            print(Thread.current)
            print("Операция полностью завершена!")
        }

        operationFirst.start()

        operationSecond.priority = .background
        operationSecond.completionBlockHandler = {
            for _ in 0 ..< 50 {
                print(1)
            }
            print(Thread.current)
            print("Операция полностью завершена!")
        }
        operationSecond.start()
    }
}

// Задача 3
/// SecondRecipeViewController
final class SecondRecipeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let rmOperationQueue = RMOperationQueue()

        let rmOperation1 = RMOperation()
        rmOperation1.priority = .background

        rmOperation1.completionBlockHandler = {
            print(1)
        }

        let rmOperation2 = RMOperation()
        rmOperation2.priority = .userInteractive

        rmOperation2.completionBlockHandler = {
            print(2)
        }

        let rmOperation3 = RMOperation()
        rmOperation3.priority = .userInteractive
        rmOperation3.completionBlockHandler = {
            print(3)
        }

        let rmOperation4 = RMOperation()
        rmOperation4.priority = .userInteractive
        rmOperation4.completionBlockHandler = {
            print(4)
        }

        rmOperationQueue.addOperation(rmOperation1)
        rmOperationQueue.addOperation(rmOperation2)
        rmOperationQueue.addOperation(rmOperation3)
        rmOperationQueue.addOperation(rmOperation4)
    }
}

protocol RMOperationQueueProtocol {
    /// Тут храним пул наших операций
    var operations: [RMOperation] { get }
    /// Добавляем наши кастомные операции в пул operations
    func addOperation(_ operation: RMOperation)
    /// Запускаем следующую
    func executeNextOperation()
}

// Класс, управляющий очередью операций
final class RMOperationQueue: RMOperationQueueProtocol {
    var operations: [RMOperation] = []

    func addOperation(_ operation: RMOperation) {
        operations.append(operation)
        executeNextOperation()
    }

    func executeNextOperation() {
        if let nextOperation = operations.first(where: { !$0.isExecuting && !$0.isFinished }) {
            nextOperation.start()
            executeNextOperation()
        }
    }
}

// Задача 4.
// Проблема называется гонка доступов (по крайней мере, санитайзер предупреждает о ней), т.к. обе операции пытаются
// записать в массив данные, т.е. совершают равнозначные
// операции.
/// OperationQueueController
final class OperationQueueController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Использование
        let threadSafeArray = ThreadSafeArray()
        let operationQueue = OperationQueue()

        let firstOperation = FirstOperation(threadSafeArray: threadSafeArray)
        let secondOperation = SecondOperation(threadSafeArray: threadSafeArray)

        // второй вариант решения - установка зависимостей
        // secondOperation.addDependency(firstOperation)
        operationQueue.addOperation(firstOperation)
        operationQueue.addOperation(secondOperation)

        // Дождитесь завершения операций перед выводом содержимого массива
        operationQueue.waitUntilAllOperationsAreFinished()

        print(threadSafeArray.getAll())
    }
}

// Объявляем класс для для синхронизации потоков
class ThreadSafeArray {
    private var array: [String] = []
    var semaphore = DispatchSemaphore(value: 1)

    func append(_ item: String) {
        // первый вариант решения - с семафорами
        semaphore.wait()
        array.append(item)
        semaphore.signal()
    }

    func getAll() -> [String] {
        array
    }
}

// Определяем первую операцию для добавления строки в массив
final class FirstOperation: Operation {
    let threadSafeArray: ThreadSafeArray

    init(threadSafeArray: ThreadSafeArray) {
        self.threadSafeArray = threadSafeArray
    }

    override func main() {
        if isCancelled { return }
        threadSafeArray.append("Первая операция")
    }
}

// Определяем вторую операцию для добавления строки в массив
final class SecondOperation: Operation {
    let threadSafeArray: ThreadSafeArray

    init(threadSafeArray: ThreadSafeArray) {
        self.threadSafeArray = threadSafeArray
    }

    override func main() {
        if isCancelled { return }
        threadSafeArray.append("Вторая операция")
    }
}
