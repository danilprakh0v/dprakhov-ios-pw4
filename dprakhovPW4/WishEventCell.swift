//
//  WishEventCell.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class WishEventCell: UICollectionViewCell {
    
    // Идентификатор для переиспользования ячейки.
    static let reuseId = "WishEventCell"
    
    // MARK: - Public Properties
    
    // Активное использование побуждающих замыканий.
    public var onDelete: (() -> Void)?
    public var onShare: (() -> Void)?
    
    // MARK: - Constants
    
    // Храним настройки внешнего вида в одном месте.
    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let contentPadding: CGFloat = 16
        // Шрифты: используем разный вес (weight) для визуальной иерархии.
        static let titleFont = UIFont.systemFont(ofSize: 22, weight: .heavy)
        static let descriptionFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        static let dateFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
    }
    
    // MARK: - UI Elements
    
    // Создаем лейблы через вспомогательную функцию (фабричный метод), чтобы не дублировать код.
    private let titleLabel = makeLabel(font: Constants.titleFont)
    private let descriptionLabel = makeLabel(font: Constants.descriptionFont, numberOfLines: 2)
    private let startDateLabel = makeLabel(font: Constants.dateFont)
    private let endDateLabel = makeLabel(font: Constants.dateFont)
    
    // Кнопки действий (lazy, чтобы инициализировались только при обращении, хотя здесь это не критично).
    private lazy var deleteButton = makeActionButton(systemName: "trash")
    private lazy var shareButton = makeActionButton(systemName: "square.and.arrow.up")
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupActions()
    }
    
    // Обязательный инит для Storyboard, который мы не поддерживаем.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    // Метод конфигурации. Заполняем UI данными из модели.
    // Вызывается из cellForItemAt в контроллере.
    public func configure(with event: WishEvent) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, yyyy 'at' HH:mm" // Пример: Wed, Nov 20, 2025 at 14:00
        
        // Делаем фон ячейки полупрозрачным белым.
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        contentView.layer.cornerRadius = Constants.cornerRadius
        
        titleLabel.text = event.title
        descriptionLabel.text = event.description
        startDateLabel.text = "Start: \(dateFormatter.string(from: event.startDate))"
        endDateLabel.text = "End:   \(dateFormatter.string(from: event.endDate))"
        
        // Лайфхак: красим все лейблы в белый цвет в одну строку.
        [titleLabel, descriptionLabel, startDateLabel, endDateLabel].forEach { $0.textColor = .white }
    }
    
    // MARK: - Private Methods
    
    private func setupActions() {
        // СОВРЕМЕННЫЙ ПОДХОД (iOS 14+):
        // Вместо addTarget и #selector используем UIAction с замыканием.
        // Это избавляет нас от лишних @objc методов и делает код чище.
        
        deleteButton.addAction(UIAction { [weak self] _ in
            // Вызываем внешний кложур, если он задан.
            self?.onDelete?()
        }, for: .touchUpInside)
        
        shareButton.addAction(UIAction { [weak self] _ in
            self?.onShare?()
        }, for: .touchUpInside)
    }
    
    // Фабричный метод для создания UILabel. Убирает дублирование кода настройки.
    private static func makeLabel(font: UIFont, numberOfLines: Int = 1) -> UILabel {
        let label = UILabel()
        label.font = font
        label.numberOfLines = numberOfLines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    // Фабричный метод для создания кнопок с иконками (SF Symbols).
    private func makeActionButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func setupLayout() {
        // UIStackView — мощный инструмент. Он сам расставляет элементы в ряд или столбец.
        // Это позволяет не писать констрейнты для каждого лейбла отдельно.
        
        // 1. Горизонтальный стек для кнопок (справа).
        let buttonsStack = UIStackView(arrangedSubviews: [shareButton, deleteButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12 // Расстояние между кнопками
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Вертикальный стек для текста (слева).
        // UIView() внутри массива — это "распорка" (spacer), которая может занимать пустое место,
        // но здесь она используется просто как разделитель или плейсхолдер.
        let contentStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, UIView(), startDateLabel, endDateLabel])
        contentStack.axis = .vertical
        contentStack.spacing = 6 // Расстояние между строками текста
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем стеки на contentView (важно: не на view, а именно на contentView ячейки).
        contentView.addSubview(contentStack)
        contentView.addSubview(buttonsStack)
        
        // Настраиваем Auto Layout для стеков.
        NSLayoutConstraint.activate([
            // Кнопки прибиваем к верхнему правому углу с отступами.
            buttonsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.contentPadding),
            buttonsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.contentPadding),
            
            // Текстовый блок занимает всё остальное место.
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.contentPadding),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.contentPadding),
            
            // Важный момент: правый край текста привязываем к левому краю кнопок (чтобы текст не налез на кнопки).
            // lessThanOrEqualTo дает гибкость: текст может быть короче, но не длиннее этой границы.
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: buttonsStack.leadingAnchor, constant: -Constants.contentPadding),
            
            // Привязываем низ текста к низу ячейки.
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.contentPadding)
        ])
    }
}
