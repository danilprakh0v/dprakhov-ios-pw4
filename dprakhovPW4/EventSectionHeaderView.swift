//
//  EventSectionHeaderView.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// UICollectionReusableView — это специальный класс для "дополнительных" элементов CollectionView - (хедеры и футеры).

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class EventSectionHeaderView: UICollectionReusableView {
    
    // Статическая константа для ReuseIdentifier.
    // Используем её при регистрации хедера в CollectionView, чтобы избежать опечаток в строках.
    static let reuseId = "EventSectionHeaderView"
    
    // Создаем лейбл программно - (через замыкание).
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold) // Крупный, жирный шрифт для заголовка секции.
        label.textColor = .white // Белый цвет, чтобы выделяться на фоне.
        // Обязательно отключаем маску авто-ресайза для ручной настройки констрейнтов.
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Init для создания View кодом.
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Добавляем лейбл на саму view.
        addSubview(titleLabel)
        
        // Настраиваем расположение:
        // Центрируем по вертикали и даем отступ 16 поинтов слева.
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
    }
    
    // Этот инит обязателен по требованию компилятора - (для Storyboard), но мы вызываем краш, если он сработает.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Метод конфигурации (паттерн "Configurable View").
    // View не знает, откуда берутся данные, она просто получает дату и отображает её.
    func configure(with date: Date) {
        let dateFormatter = DateFormatter()
        // Задаем формат: EEEE (день недели полностью), MMMM (месяц полностью), d (число).
        // Пример: "Wednesday, November 20"
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        // Превращаем объект Date в красивую строку.
        titleLabel.text = dateFormatter.string(from: date)
    }
}
