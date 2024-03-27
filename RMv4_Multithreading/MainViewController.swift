// MainViewController.swift
// Copyright © RoadMap. All rights reserved.

import UIKit

/// Экран входа в приложение
final class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
    }
}

// ЗАДАЧА 1.
// Какой принцип нарушает данный код? Исправьте код что б ничего не нарушал?
// Метод нарушает принцип единой ответственности, т.к. у класса, ответственного за выполнение запросов с сети, имелся метод, отвечающий за обновление вью.
final class SomeView: UIView {
    
    let networkManager = NetworkManager()
    
    func updateUI() {
        // Запрос к API через экземпляр
        // networkManager.fetchData(url: URL(string: "string")!)
        // что-то обновляет в ui
    }
}

final class NetworkManager {
    
    func fetchData(url: URL) {
        // Запрос к API
    }
}

// ЗАДАЧА 2.1.
// Какой принцип нарушает данный код? Исправьте код что б ничего не нарушал?
// В данном случае нарушается принцип открытости-закрытости, т.к. старый метод класса Animal получал слишком много изменений.
protocol Animal {
    func makeSound()
}

final class Dog: Animal {
    func makeSound() {
        print("Woof!")
    }
}

final class Cat: Animal {
    func makeSound() {
        print("Meow!")
    }
}

// ЗАДАЧА 2.2.
// Какой принцип нарушает данный код? Исправьте код что б ничего не нарушал?
// Нарушался принцип открытости-закрытости, т.к. в класс SizePrinter требовалось бы добавлять типы фигур при уведичении классов на фигуры.
protocol SizePrintable {
    func printSize()
}

///Circle
struct Circle: SizePrintable {
   let radius: CGFloat
    
    func printSize() {
         let diameter = self.radius * 2
         print(CGSize(width: diameter, height: diameter))
    }
}

///Rectangle
struct Rectangle: SizePrintable {
   let width: CGFloat
   let height: CGFloat
    
    func printSize() {
       print(CGSize(width: self.width, height: self.height))
     }
}

// ЗАДАЧА 3.
// Какой принцип нарушает данный код? Исправьте код, чтоб ничего не нарушал.
// Данный код нарушает принцип подстановки Лисков, так как поведение потомка не соответствует ожидаемому поведению, унаследованному от родителя.
class Bird {
    func move() {
        print("Default bird flies")
    }
}

final class Penguin: Bird {
    override func move() {
       print("Penguin slides")
    }
}

let myBird: Bird = Penguin()
//myBird.fly()   "Penguin slides"

// ЗАДАЧА 4.
// Какой принцип нарушает данный код? Исправьте код, чтоб ничего не нарушал.
// Нарушает принцип разделения интерфейсов, т.к. до изменений класс имплементировал не нужный ему метод из-за неверной группировки методов в один протокол.
protocol Worker {
    func work()
}

protocol Eater {
    func eat()
}

final class Robot: Worker {
    func work() {
        // Робот работает
    }
}

// пример чуть развивается
final class Human: Worker, Eater {
    func work() {
        // works
    }
    
    func eat() {
        // eats
    }
}


// ЗАДАЧА 5.
// Какой принцип нарушает данный код? Исправьте код, чтоб ничего не нарушал.
// Класс верхнего уровня - LightBulb
// нарушается принцип инверсии зависимостей, т.к. свитчер зависел от конкретного класса, а не абстрактного интерфейса.

// переключающий протокол
protocol Switchable {
    func turnOn()
    func turnOff()
}

// протокол для самой лампы, иначе методы в воздухе висели
protocol Lamp {
    func on()
    func off()
}

final class LightBulb {
    let lamp: Lamp
    
    init(lamp: Lamp) {
        self.lamp = lamp
    }
    
    func turnOn() {
        // включает свет
    lamp.on()
    }

    func turnOff() {
        // включает свет
    lamp.off()
    }
}

class Switch {
    let bulb: Switchable

    init(bulb: Switchable) {
        self.bulb = bulb
    }

    func toggle() {
        bulb.turnOn()
    }
}
