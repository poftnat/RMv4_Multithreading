// MainViewController.swift
// Copyright © RoadMap. All rights reserved.

import UIKit

// Контроллер под задание таск 1 - "Разгрузить главный поток"
/// MainViewController
final class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow

        Thread.detachNewThread {
            for _ in 0 ..< 10 {
                let currentThread = Thread.current
                print("1, Current thread: \(currentThread)")
            }
        }

        for _ in 0 ..< 10 {
            let currentThread = Thread.current
            print("2, Current thread: \(currentThread)")
        }
        // разница в результате объясняется тем, что выполнение первого цикла перенаправлено в другой поток, поэтому
        // задачи выполняются одновременно.
    }
}

// Контроллер для выполнения вопроса таск 1 - "Создать второй поток на базе Thread и таймер"
/// SecondQuestionViewcontroller
final class SecondQuestionViewcontroller: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let timer = TimerThread(duration: 10)
        timer.start()
    }
}

/// NewThread
class NewThread: Thread {
    override func main() {
        RunLoop.current.run()
    }
}

/// TimerThread
class TimerThread: Thread {
    private var timerDuration: Int
    private var timer: Timer!

    init(duration: Int) {
        timerDuration = duration
    }

    override func main() {
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .default)
        RunLoop.current.run()
        print(Thread.current)
    }

    @objc func updateTimer() {
        if timerDuration > 0 {
            print("Осталось \(timerDuration) секунд...")
            timerDuration -= 1
        } else {
            print("Время истекло!")

            timer.invalidate()
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
}

// Контроллер для выполнения таск 2 - "Отменить, когда цикл досчитает до 5, расставить флаги"
/// ThirdQuestionViewController
final class ThirdQuestionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let infinityThread = InfinityLoop()
        infinityThread.start()
        sleep(5)
        print(infinityThread.isExecuting, infinityThread.isCancelled, infinityThread.isFinished)
        infinityThread.cancel()
        print(infinityThread.isExecuting, infinityThread.isCancelled, infinityThread.isFinished)
    }
}

/// InfinityLoop Thread
final class InfinityLoop: Thread {
    var counter = 0

    override func main() {
        while counter < 30, !isCancelled {
            counter += 1
            print(counter)
            InfinityLoop.sleep(forTimeInterval: 1)
            print(isExecuting, isCancelled, isFinished)
        }
    }
}

// Контроллер для выполнения таск 2 - "Отменить, когда цикл досчитает до 5, расставить флаги"
/// FourthQuestionViewController
final class FourthQuestionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let thread1 = ThreadprintDemon()
        let thread2 = ThreadprintAngel()
        thread2.qualityOfService = .userInitiated
        thread1.qualityOfService = .userInitiated

        thread1.start()
        thread2.start()
    }
}

/// ThreadprintDemon
final class ThreadprintDemon: Thread {
    override func main() {
        for _ in 0 ..< 100 {
            print("1")
        }
    }
}

/// ThreadprintAngel
final class ThreadprintAngel: Thread {
    override func main() {
        for _ in 0 ..< 100 {
            print("2")
        }
    }
}

// Контроллер для выполнения таск 2 - "Набрать пример, найти проблему, использовать Thread Sanitizer и пользовательскую
// очередь"
/// FifthQuestionViewController
final class FifthQuestionViewController: UIViewController {
    private var name = "Введите имя"
    private let lockQueue = DispatchQueue(label: "name.lock.queue")

    override func viewDidLoad() {
        super.viewDidLoad()

        updateName()
    }

    func updateName() {
        DispatchQueue.global().async {
            self.lockQueue.async {
                self.name = "I love RM" // Перезаписываем имя в другом потоке
                print(Thread.current)
                print(self.name)
            }
        }
        lockQueue.async {
            print(self.name) // Считываем имя из main
        }
    }
}

// Контроллер для выполнения таск 2 - "Набрать пример, найти проблему, использовать Thread Sanitizer и lock"
// Проблема - попытка инициализации ленивой переменной из нескольких потоков.
// Исправлено блокированием локером переменной из метода, который к нему обращается.
/// SixthQuestionViewcontroller
final class SixthQuestionViewcontroller: UIViewController {
    var lock = NSLock()
    private lazy var name = "I love RM"

    override func viewDidLoad() {
        super.viewDidLoad()

        updateName()
    }

    func updateName() {
        DispatchQueue.global().async {
            self.lock.lock()
            print(self.name) // Считываем имя из global
            self.lock.unlock()
            print(Thread.current)
        }

        lock.lock()
        print(name) // Считываем имя из main
        lock.unlock()
    }
}
