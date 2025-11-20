//
//  WishMakerViewController.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class WishMakerViewController: UIViewController {
    
    // MARK: - Constants
    // Все настройки размеров, шрифтов, текстов и цветов храним в enum.
    // Это позволяет менять дизайн в одном месте, не бегая по всему коду.
    private enum Constants {
        static let logoTopOffset: CGFloat = -20 // Смещение логотипа вверх.
        static let logoSizeMultiplier: CGFloat = 0.95
        
        static let initialRed: CGFloat = 0.196
        static let initialGreen: CGFloat = 0.678
        static let initialBlue: CGFloat = 0.8
        
        static let descriptionText = "This wonderful app can make your wishes come true!\nLet's start with the first wish: may it change its background color according to your desire!"
        static let descriptionBoldPart = "This wonderful app can make your wishes come true!"
        static let tadahText = "Ta-Dah!"
        
        static let wishesButtonTitle = "Add more wishes"
        static let scheduleButtonTitle = "Schedule wish granting"
        
        static let descriptionRegularFont = UIFont.systemFont(ofSize: 24, weight: .regular)
        static let descriptionBoldFont = UIFont.systemFont(ofSize: 26, weight: .bold)
        static let tadahFont = UIFont.systemFont(ofSize: 36, weight: .heavy)
        static let buttonsFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        
        static let buttonsCornerRadius: CGFloat = 16
        static let slidersStackViewCornerRadius: CGFloat = 24
        static let slidersStackViewMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        
        static let fadeInDuration: TimeInterval = 0.3
        static let displayDuration: TimeInterval = 1.0
        static let fadeOutDuration: TimeInterval = 0.5
        
        static let horizontalPadding: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let bottomPadding: CGFloat = -20
        static let spacingBetweenSlidersAndButtons: CGFloat = -20
        static let tadahBottomOffset: CGFloat = -20
        static let buttonsStackViewSpacing: CGFloat = 12
    }
    
    // MARK: - Properties
    
    // Переменные состояния для текущего цвета.
    private var redComponent: CGFloat = Constants.initialRed
    private var greenComponent: CGFloat = Constants.initialGreen
    private var blueComponent: CGFloat = Constants.initialBlue

    // MARK: - UI Elements
    
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "WishMakerLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Низкий приоритет сжатия по вертикали, чтобы картинка сжималась первой, если места мало.
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        // Создаем AttributedString для разного форматирования внутри одной строки.
        let attributedString = NSMutableAttributedString(string: Constants.descriptionText, attributes: [.font: Constants.descriptionRegularFont])
        // Находим диапазон жирного текста и меняем ему шрифт.
        let boldRange = (Constants.descriptionText as NSString).range(of: Constants.descriptionBoldPart)
        attributedString.addAttribute(.font, value: Constants.descriptionBoldFont, range: boldRange)
        
        label.attributedText = attributedString
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0 // Многострочный текст.
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    // Лейбл для анимации при нажатии на слайдер.
    // Изначально невидим.
    private lazy var tadahLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.tadahText
        label.font = Constants.tadahFont
        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 0.0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Кастомные слайдеры.
    private let redSlider = CustomSlider(title: "Red", min: 0, max: 1)
    private let greenSlider = CustomSlider(title: "Green", min: 0, max: 1)
    private let blueSlider = CustomSlider(title: "Blue", min: 0, max: 1)

    // Стек для слайдеров.
    // Упрощает верстку списка элементов.
    private lazy var slidersStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [redSlider, greenSlider, blueSlider])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .white
        stackView.layer.cornerRadius = Constants.slidersStackViewCornerRadius
        stackView.clipsToBounds = true
        // Внутренние отступы (padding) внутри стека.
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = Constants.slidersStackViewMargins
        return stackView
    }()
    
    // Кнопки создаются через фабричный метод.
    private lazy var wishesButton: UIButton = {
        return makeButton(with: Constants.wishesButtonTitle)
    }()
    
    private lazy var scheduleButton: UIButton = {
        return makeButton(with: Constants.scheduleButtonTitle)
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [wishesButton, scheduleButton])
        stackView.axis = .vertical
        stackView.spacing = Constants.buttonsStackViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Сборка UI, настройка действий и начальных значений.
        configureUI()
        setupActions()
        setupInitialValues()
    }
    
    // Скрываем навигационный бар на этом экране для красоты - (fullscreen experience).
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // Возвращаем бар, когда уходим с экрана, чтобы на следующих экранах была кнопка "Назад".
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Setup & Logic
    
    // Фабричный метод для создания однотипных кнопок.
    private func makeButton(with title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Constants.buttonsFont
        button.backgroundColor = .white
        button.layer.cornerRadius = Constants.buttonsCornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        // Фиксируем высоту кнопки.
        button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true
        return button
    }
    
    private func setupInitialValues() {
        redSlider.slider.value = Float(Constants.initialRed)
        greenSlider.slider.value = Float(Constants.initialGreen)
        blueSlider.slider.value = Float(Constants.initialBlue)
        updateBackgroundColor()
    }
    
    private func setupActions() {
        // 1. Настройка слайдеров (изменение цвета).
        // Используем замыкание, которое мы определили в CustomSlider.
        redSlider.valueChanged = { [weak self] value in
            self?.redComponent = CGFloat(value)
            self?.updateBackgroundColor()
        }
        greenSlider.valueChanged = { [weak self] value in
            self?.greenComponent = CGFloat(value)
            self?.updateBackgroundColor()
        }
        blueSlider.valueChanged = { [weak self] value in
            self?.blueComponent = CGFloat(value)
            self?.updateBackgroundColor()
        }
        
        // 2. Анимация "Ta-Dah" при отпускании слайдера.
        [redSlider, greenSlider, blueSlider].forEach { slider in
            slider.slider.addAction(UIAction { [weak self] _ in
                self?.showTadahAnimation()
            }, for: .touchUpInside)
        }
        
        // 3. Навигация (Кнопки).
        wishesButton.addAction(UIAction { [weak self] _ in
            self?.navigateToWishStoring()
        }, for: .touchUpInside)
        
        scheduleButton.addAction(UIAction { [weak self] _ in
            self?.navigateToCalendar()
        }, for: .touchUpInside)
    }
    
    // Логика перехода на экран списка желаний.
    private func navigateToWishStoring() {
        let wishStoringVC = WishStoringViewController()
        // Передаем текущий цвет фона, чтобы сохранить тему.
        wishStoringVC.themeColor = view.backgroundColor ?? .systemGray6
        navigationController?.pushViewController(wishStoringVC, animated: true)
    }
    
    // Логика перехода на экран календаря.
    private func navigateToCalendar() {
        let calendarVC = WishCalendarViewController()
        calendarVC.themeColor = view.backgroundColor ?? .systemGray6
        navigationController?.pushViewController(calendarVC, animated: true)
    }
    
    // Обновление цвета фона и элементов интерфейса.
    private func updateBackgroundColor() {
        let newColor = UIColor(red: redComponent, green: greenComponent, blue: blueComponent, alpha: 1.0)
        view.backgroundColor = newColor
        
        // Красим полоски слайдеров и текст кнопок в цвет фона для гармонии.
        [redSlider, greenSlider, blueSlider].forEach { $0.setSliderColor(color: newColor) }
        [wishesButton, scheduleButton].forEach { $0.setTitleColor(newColor, for: .normal) }
    }
    
    // Анимация появления и исчезновения надписи.
    private func showTadahAnimation() {
        // Защита от повторного запуска, пока анимация идет.
        guard tadahLabel.alpha == 0.0 else { return }
        
        UIView.animate(withDuration: Constants.fadeInDuration, animations: {
            self.tadahLabel.alpha = 1.0
        }) { _ in
            // Ждем 1 секунду и запускаем исчезновение.
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.displayDuration) {
                UIView.animate(withDuration: Constants.fadeOutDuration) {
                    self.tadahLabel.alpha = 0.0
                }
            }
        }
    }

    // Верстка экрана кодом (Auto Layout).
    private func configureUI() {
        view.addSubview(logoImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(slidersStackView)
        view.addSubview(buttonsStackView)
        view.addSubview(tadahLabel)
        
        NSLayoutConstraint.activate([
            // Кнопки прижаты к низу (Safe Area).
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalPadding),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalPadding),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Constants.bottomPadding),
            
            // Слайдеры находятся над кнопками.
            slidersStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalPadding),
            slidersStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalPadding),
            slidersStackView.bottomAnchor.constraint(equalTo: buttonsStackView.topAnchor, constant: Constants.spacingBetweenSlidersAndButtons),
            
            // Логотип наверху.
            // ИЗМЕНЕНО: Добавлено смещение логотипа вверх (logoTopOffset).
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.logoTopOffset),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Размер логотипа относительно ширины экрана.
            logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: Constants.logoSizeMultiplier),
            
            // Описание под логотипом.
            descriptionLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: -20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalPadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalPadding),
            // Описание не должно налезать на Ta-Dah лейбл.
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: tadahLabel.topAnchor, constant: -8),
            
            // Ta-Dah лейбл между описанием и слайдерами.
            tadahLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tadahLabel.bottomAnchor.constraint(equalTo: slidersStackView.topAnchor, constant: Constants.tadahBottomOffset)
        ])
    }
}
