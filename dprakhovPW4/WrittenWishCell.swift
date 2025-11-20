//
//  WrittenWishCell.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class WrittenWishCell: UITableViewCell {
    
    // Идентификатор для переиспользования (Reusing).
    // Таблица не создает 1000 ячеек для 1000 строк, а использует ~10 штук, меняя в них данные.
    static let reuseId = "WrittenWishCell"
    
    // MARK: - Constants
    // Выносим размеры и шрифты в константы для удобства правки дизайна.
    private enum Constants {
        static let containerCornerRadius: CGFloat = 16
        static let wishNumberFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        static let wishTextFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        // Отступы для "карточки" от краев ячейки.
        static let containerVerticalPadding: CGFloat = 5
        static let containerHorizontalPadding: CGFloat = 20
        
        // Внутренние отступы текста внутри "карточки".
        static let labelInternalPadding: CGFloat = 16
    }
    
    // MARK: - UI Elements
    
    // "Карточка" — белая подложка с закругленными углами.
    // Сама ячейка (contentView) будет прозрачной, а этот view создаст эффект карточки.
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.containerCornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let wishNumberLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.wishNumberFont
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let wishTextLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.wishTextFont
        // 0 означает "бесконечное" количество строк. Таблица сама растянет ячейку по высоте текста.
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    
    // Стандартный инициализатор для ячейки кодом.
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    // Метод для заполнения ячейки данными.
    // themeColor позволяет покрасить текст в цвет текущего фона приложения (для стиля).
    public func configure(wishText: String, wishNumber: Int, themeColor: UIColor) {
        wishNumberLabel.text = "Wish №\(wishNumber):"
        wishTextLabel.text = wishText
        
        wishNumberLabel.textColor = themeColor
        wishTextLabel.textColor = themeColor
    }
    
    // MARK: - Private Setup
    
    private func setupCell() {
        // Убираем серую подсветку при нажатии (для красоты).
        selectionStyle = .none
        // Делаем фон самой ячейки прозрачным, чтобы виден был только containerView.
        backgroundColor = .clear
    }
    
    private func setupLayout() {
        // 1. Добавляем "карточку" на content view ячейки.
        contentView.addSubview(containerView)
        
        // 2. Собираем тексты в вертикальный StackView.
        // Это проще, чем настраивать констрейнты между лейблами вручную.
        let stackView = UIStackView(arrangedSubviews: [wishNumberLabel, wishTextLabel])
        stackView.axis = .vertical
        stackView.spacing = 4 // Расстояние между заголовком и текстом.
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Добавляем стек ВНУТРЬ карточки.
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            // Внешние отступы: Карточка отступает от краев ячейки.
            // Это создает "промежутки" между ячейками в таблице.
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.containerVerticalPadding),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.containerHorizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.containerHorizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.containerVerticalPadding),
            
            // Внутренние отступы: Текст отступает от краев карточки.
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.labelInternalPadding),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.labelInternalPadding),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.labelInternalPadding),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.labelInternalPadding)
        ])
    }
}
