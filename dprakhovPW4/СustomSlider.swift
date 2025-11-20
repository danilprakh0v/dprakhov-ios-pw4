//
//  CustomSlider.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class CustomSlider: UIView {

    // MARK: - Variables
    
    // С помощью замыкания мы сообщим ViewController'у, что ползунок сдвинулся, передавая новое значение.
    var valueChanged: ((Double) -> Void)?
    
    // Сам слайдер делаем public, чтобы из контроллера можно было добавить к нему
    // дополнительные настройки - (например, отслеживать отпускание пальца).
    public let slider = UISlider()

    // Создаем и настраиваем лейбл сразу внутри замыкания.
    // Это делает код чище и собирает всю настройку UI-элемента в одном месте.
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        // Важно: отключаем авто-ресайз маски, иначе Auto Layout не сработает как надо.
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    
    // Кастомный инициализатор.
    // Принимаем заголовок и границы значений (min/max).
    init(title: String, min: Double, max: Double) {
        // Frame .zero, потому что размеры мы зададим позже через констрейнты.
        super.init(frame: .zero)
        
        titleLabel.text = title
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        
        // Используем UIAction вместо прежнего addTarget и #selector - небольшой рефакторинг.
        // Теперь логика обработки находится прямо здесь, а не в отдельной функции.
        // [weak self] — обязательная страховка от утечек памяти - (retain cycles).
        slider.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            // Передаем значение слайдера наружу через наше замыкание.
            self.valueChanged?(Double(self.slider.value))
        }, for: .valueChanged)
        
        // Запускаем верстку.
        configureUI()
    }
    
    // Этот инит требует Xcode, если мы вдруг решим использовать Storyboard (но мы его уже удалили и не используем).
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods
    
    // Метод-помощник, чтобы контроллер мог легко поменять цвет полоски слайдера.
    func setSliderColor(color: UIColor) {
        slider.minimumTrackTintColor = color
    }

    // MARK: - Private Methods & UI
    
    private func configureUI() {
        // Обязательно отключаем маску для самого view и слайдера,
        // иначе констрейнты будут конфликтовать с системными рамками.
        translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // Делаем "неактивную" часть полоски полупрозрачной серой.
        slider.maximumTrackTintColor = .lightGray.withAlphaComponent(0.5)
        
        // Добавляем элементы на вьюшку.
        addSubview(titleLabel)
        addSubview(slider)
        
        // Auto Layout: притягиваем элементы к anchor'ам (якорям).
        NSLayoutConstraint.activate([
            // Заголовок притягиваем к верху, левому и правому краям.
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // Слайдер ставим ПОД заголовком с отступом 12 поинтов.
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // Важно: прибиваем слайдер к низу container-view с отступом.
            // Это позволяет родительскому view растягиваться по высоте содержимого.
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}
