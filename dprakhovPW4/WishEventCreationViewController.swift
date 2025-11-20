//
//  WishEventCreationViewController.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// Этот контроллер отвечает и за создание, и за редактирование события.
// Мы используем presentationStyle = .overCurrentContext, чтобы фон был прозрачным.
final class WishEventCreationViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Constants
    // Храним все "магические числа" и строки в одном месте.
    // Это делает код чище и упрощает правки дизайна, исключая неясность используемых параметров.
    private enum Constants {
        static let titleCreate = "Create New Event"
        static let titleEdit = "Edit Event"
        static let selectWishTitle = "Select a Wish"
        static let saveButtonTitle = "Save Event"
        static let descriptionPlaceholder = "Add a description..."
        
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let descriptionHeight: CGFloat = 90
        static let saveButtonHeight: CGFloat = 50
        static let mainStackSpacing: CGFloat = 16
        
        static let cardBackgroundColor = UIColor.secondarySystemGroupedBackground
        static let iconColor = UIColor.systemGray
        static let calendarIcon = "calendar"
        static let flagIcon = "flag.fill"
    }
    
    // MARK: - Public Properties
    
    // Замыкание, которые мы вызовем, когда пользователь нажмет "Save".
    // Контроллер-родитель подпишется на него и получит готовое событие.
    public var onSave: ((WishEvent) -> Void)?
    
    // Данные, которые нам передадут извне.
    public var availableWishes: [String] = []
    public var eventToEdit: WishEvent? // Если nil — значит режим создания, иначе — редактирование.

    // MARK: - Private Properties
    private var selectedWish: String?
    
    // MARK: - UI Elements
    
    // Используем lazy var, потому что внутри инициализации мы используем self (вызов методов makeLabel, makeButton).
    // Если бы это были просто let, компилятор бы ругался, так как self еще не готов.
    private lazy var titleLabel = self.makeLabel(text: "", font: .boldSystemFont(ofSize: 28))
    private lazy var wishPickerButton = self.makeButton(title: Constants.selectWishTitle)
    private lazy var descriptionTextView = self.makeTextView()
    private lazy var startDatePicker = self.makeDatePicker()
    private lazy var endDatePicker = self.makeDatePicker()
    private lazy var saveButton = self.makeButton(title: Constants.saveButtonTitle, backgroundColor: .systemBlue, titleColor: .white)
    
    // Эффект размытия заднего фона (Blur).
    private let blurView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        return blur
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Делаем фон самого view прозрачным, чтобы было видно blurView и контент под ним.
        view.backgroundColor = .clear
        // overCurrentContext позволяет показать этот контроллер поверх предыдущего, не удаляя тот из памяти.
        modalPresentationStyle = .overCurrentContext
        
        descriptionTextView.delegate = self // Подписываемся на события ввода текста.
        setupLayout()
        setupActions()
        configureForEditing()
    }
    
    // MARK: - Setup Methods
    
    // Проверяем, редактируем мы событие или создаем новое.
    private func configureForEditing() {
        if let event = eventToEdit {
            // Режим редактирования: заполняем поля существующими данными.
            titleLabel.text = Constants.titleEdit
            selectedWish = event.title
            wishPickerButton.setTitle(event.title, for: .normal)
            descriptionTextView.text = event.description
            descriptionTextView.textColor = .label // Цвет текста — обычный (не серый плейсхолдер).
            startDatePicker.date = event.startDate
            endDatePicker.date = event.endDate
        } else {
            // Режим создания.
            titleLabel.text = Constants.titleCreate
        }
    }
    
    private func setupActions() {
        // СОВРЕМЕННЫЙ ПОДХОД (UIAction):
        // Привязываем действия к кнопкам через замыкания.
        
        wishPickerButton.addAction(UIAction { [weak self] _ in
            self?.showWishPicker()
        }, for: .touchUpInside)
        
        saveButton.addAction(UIAction { [weak self] _ in
            self?.saveTapped()
        }, for: .touchUpInside)
    }
    
    private func setupLayout() {
        view.addSubview(blurView)
        
        // Создаем "карточки" — белые прямоугольники со скругленными углами.
        let wishCard = makeCardView()
        let dateCard = makeCardView()
        
        // Верстка выбора желания.
        let separatorWish = makeSeparatorView()
        let wishStack = UIStackView(arrangedSubviews: [wishPickerButton, separatorWish, descriptionTextView])
        wishStack.axis = .vertical
        wishStack.translatesAutoresizingMaskIntoConstraints = false
        wishCard.addSubview(wishStack)
        
        // Верстка дат (start и end).
        let startRow = makeDateRow(iconName: Constants.calendarIcon, labelText: "Start", datePicker: startDatePicker)
        let endRow = makeDateRow(iconName: Constants.flagIcon, labelText: "End", datePicker: endDatePicker)
        let separatorDate = makeSeparatorView()
        let dateStack = UIStackView(arrangedSubviews: [startRow, separatorDate, endRow])
        dateStack.axis = .vertical
        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dateCard.addSubview(dateStack)

        // Главный вертикальный стек, который держит всё вместе.
        let mainStack = UIStackView(arrangedSubviews: [
            titleLabel, wishCard, dateCard, UIView(), saveButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = Constants.mainStackSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        // Добавляем стек на contentView блюра, чтобы он был "внутри" эффекта размытия.
        blurView.contentView.addSubview(mainStack)

        // Хелпер edges(to:) растягивает wishStack на всю карточку.
        wishStack.edges(to: wishCard)
        
        // Констрейнты
        NSLayoutConstraint.activate([
            // Даты внутри карточки с отступами.
            dateStack.topAnchor.constraint(equalTo: dateCard.topAnchor),
            dateStack.bottomAnchor.constraint(equalTo: dateCard.bottomAnchor),
            dateStack.leadingAnchor.constraint(equalTo: dateCard.leadingAnchor, constant: Constants.padding),
            dateStack.trailingAnchor.constraint(equalTo: dateCard.trailingAnchor, constant: -Constants.padding),

            // Блюр на весь экран.
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Высота разделителей (1 пиксель).
            separatorWish.heightAnchor.constraint(equalToConstant: 1),
            separatorDate.heightAnchor.constraint(equalToConstant: 1),

            // Высоты элементов ввода.
            descriptionTextView.heightAnchor.constraint(equalToConstant: Constants.descriptionHeight),
            saveButton.heightAnchor.constraint(equalToConstant: Constants.saveButtonHeight),
            wishPickerButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Главный стек с отступами от Safe Area.
            mainStack.topAnchor.constraint(equalTo: blurView.contentView.safeAreaLayoutGuide.topAnchor, constant: Constants.padding),
            mainStack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: Constants.padding),
            mainStack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -Constants.padding),
            mainStack.bottomAnchor.constraint(equalTo: blurView.contentView.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.padding)
        ])
    }
    
    // MARK: - Logic Methods
    
    // Логика сохранения. Больше не нуждается в @objc.
    private func saveTapped() {
        // Проверяем: если текст совпадает с плейсхолдером, считаем поле пустым.
        let descriptionText = (descriptionTextView.text == Constants.descriptionPlaceholder) ? "" : descriptionTextView.text
        
        // Валидация данных.
        guard let title = selectedWish,
              let description = descriptionText, !description.isEmpty,
              endDatePicker.date > startDatePicker.date else { // Дата конца должна быть позже начала.
            
            let alert = UIAlertController(title: "Validation Error", message: "Please select a wish, add a description, and ensure the end date is after the start date.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Если редактируем — берем старый ID, если создаем — генерируем новый UUID.
        let eventId = eventToEdit?.id ?? UUID()
        let eventToSave = WishEvent(id: eventId, title: title, description: description, startDate: startDatePicker.date, endDate: endDatePicker.date)
        
        // Передаем данные родителю через замыкание.
        onSave?(eventToSave)
        dismiss(animated: true)
    }
    
    // Показ ActionSheet для выбора желания.
    private func showWishPicker() {
        let alert = UIAlertController(title: "Select a Wish", message: nil, preferredStyle: .actionSheet)
        
        for wish in availableWishes {
            alert.addAction(UIAlertAction(title: wish, style: .default, handler: { [weak self] _ in
                self?.selectedWish = wish
                self?.wishPickerButton.setTitle(wish, for: .normal)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - UITextViewDelegate
    
    // Эмуляция Placeholder'а для UITextView (в UIKit у него нет встроенного свойства placeholder).
    
    // Когда начинаем печатать: если текст серый (плейсхолдер), стираем его и делаем цвет черным.
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    // Когда закончили печатать: если пусто, возвращаем серый текст плейсхолдера.
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = Constants.descriptionPlaceholder
            textView.textColor = .placeholderText
        }
    }
    
    // MARK: - Factory Methods
    // Методы для создания UI-элементов. Позволяют разгрузить viewDidLoad и не дублировать код.
    
    private func makeLabel(text: String, font: UIFont = .systemFont(ofSize: 16)) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func makeButton(title: String, backgroundColor: UIColor? = Constants.cardBackgroundColor, titleColor: UIColor = .label) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Используем современную конфигурацию кнопок (iOS 15+).
        if #available(iOS 15.0, *) {
            var config: UIButton.Configuration
            if backgroundColor == .systemBlue {
                config = .filled() // Залитая кнопка (Save).
                config.baseBackgroundColor = .systemBlue
                config.baseForegroundColor = titleColor
                config.cornerStyle = .large
            } else {
                config = .plain() // Обычная кнопка.
                config.background.backgroundColor = backgroundColor
                config.background.cornerRadius = Constants.cornerRadius
                config.baseForegroundColor = titleColor
                config.titleAlignment = .leading
                config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            }
            // AttributedString нужен для настройки шрифта внутри Configuration.
            var attributedTitle = AttributedString(title)
            attributedTitle.font = .systemFont(ofSize: 17)
            config.attributedTitle = attributedTitle
            button.configuration = config
        } else {
            // Фолбэк для старых iOS (на всякий случай).
            button.setTitle(title, for: .normal)
            button.backgroundColor = backgroundColor
            button.layer.cornerRadius = Constants.cornerRadius
            button.setTitleColor(titleColor, for: .normal)
            if backgroundColor != .systemBlue {
                button.contentHorizontalAlignment = .leading
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
        }
        return button
    }
    
    private func makeTextView() -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        // Изначально ставим текст плейсхолдера и серый цвет.
        textView.text = Constants.descriptionPlaceholder
        textView.textColor = .placeholderText
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }
    
    private func makeDatePicker() -> UIDatePicker {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }
    
    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = Constants.cardBackgroundColor
        view.layer.cornerRadius = Constants.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private func makeSeparatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    // Создает строку с иконкой, текстом и дейт-пикером.
    private func makeDateRow(iconName: String, labelText: String, datePicker: UIDatePicker) -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = Constants.iconColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = makeLabel(text: labelText, font: .systemFont(ofSize: 17))
        
        // Пустая вьюшка-распорка, чтобы отодвинуть Picker вправо.
        let spacerView = UIView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [iconView, label, spacerView, datePicker])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            stack.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return stack
    }
}

// Расширение для удобной привязки краев View к другой View.
// fileprivate означает, что этот код виден только внутри этого файла.
fileprivate extension UIView {
    func edges(to view: UIView) {
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
