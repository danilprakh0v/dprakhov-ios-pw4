//
//  WishCalendarViewController.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// Вспомогательная структура.
// CollectionView работает с секциями и ячейками.
// Чтобы отображать события по дням, нам удобно сгруппировать их:
//  одна дата = одна секция = массив событий в ней.
private struct EventSection {
    let date: Date
    var events: [WishEvent]
}

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class WishCalendarViewController: UIViewController {
    
    // MARK: - Constants
    // Храним все "магические числа" и строки в одном месте.
    // Это делает код чище и упрощает правки дизайна, исключая неясность используемых параметров.
    private enum Constants {
        static let eventsKey = "myEventsArrayKey"
        static let navBarTitle = "Events Calendar"
        static let cellHeight: CGFloat = 160
        static let cellHorizontalPadding: CGFloat = 20
        static let cellVerticalSpacing: CGFloat = 12
        static let headerHeight: CGFloat = 50
    }
    
    // MARK: - Properties
    
    // Цвет темы, который можно задать извне.
    public var themeColor: UIColor = .systemGray6
    
    // "Сырой" массив всех событий.
    private var events: [WishEvent] = []
    
    // Подготовленный источник данных для CollectionView (события, разбитые по дням).
    private var eventSections: [EventSection] = []
    
    // Список желаний для выбора при создании события.
    private var wishes: [String] = []
    
    // MARK: - UI Elements
    
    // Ленивая инициализация CollectionView.
    // Используем UICollectionViewFlowLayout для стандартного списочного отображения.
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.showsVerticalScrollIndicator = false
        // Скрываем полоску прокрутки для красоты.
        
        return collection
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Порядок важен: сначала настраиваем вид, потом загружаем данные.
        applyTheme()
        setupNavigationBar()
        setupLayout()
        loadWishes()
        loadEvents()
    }
    
    // MARK: - Setup & Theme
    
    private func applyTheme() {
        view.backgroundColor = themeColor
        
        // Настройка внешнего вида навигационной панели.
        // Для iOS 15+ обязательно настраивать scrollEdgeAppearance, чтобы бар не становился прозрачным при скролле.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = themeColor
        
        // Задаем кастомный или жирный системный шрифт для заголовков.
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont(name: "Georgia-Bold", size: 34) ?? UIFont.boldSystemFont(ofSize: 34)]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont(name: "Georgia-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        // Цвет кнопок - (например, "Назад" или "+").
    }
    
    private func setupNavigationBar() {
        title = Constants.navBarTitle
        // Включаем большие заголовки (Large Titles), как в нативных приложениях Apple.
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Добавляем кнопку "+" справа.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addEventTapped))
    }
    
    private func setupLayout() {
        view.addSubview(collectionView)
        
        // Назначаем делегатов, чтобы этот контроллер управлял данными и поведением коллекции.
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Обязательная регистрация ячеек и хедеров. Без этого приложение упадет при запуске.
        collectionView.register(WishEventCell.self, forCellWithReuseIdentifier: WishEventCell.reuseId)
        collectionView.register(EventSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EventSectionHeaderView.reuseId)
        
        // Растягиваем коллекцию на весь экран.
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func addEventTapped() {
        // Открываем экран создания без передачи существующего события (nil).
        showEventCreationScreen(with: nil)
    }
    
    // Универсальный метод: используется и для создания, и для редактирования.
    private func showEventCreationScreen(with eventToEdit: WishEvent?) {
        let creationVC = WishEventCreationViewController()
        creationVC.availableWishes = self.wishes
        creationVC.eventToEdit = eventToEdit // Если передали событие, экран откроется в режиме редактирования.
        
        // Обработка замыкания (callback), которое вернет готовое событие после нажатия "Save".
        creationVC.onSave = { [weak self] savedEvent in
            self?.handleSavedEvent(savedEvent)
        }
        
        present(creationVC, animated: true)
    }
    
    // Логика сохранения события: запись в системный календарь + обновление UI.
    private func handleSavedEvent(_ event: WishEvent) {
        // Сначала пытаемся сохранить в CalendarManager.
        CalendarManager.shared.create(eventModel: event) { [weak self] success in
            // Проверяем self и успех операции.
            guard let self = self, success else {
                // Показываем ошибку, если нет доступа к календарю.
                let alert = UIAlertController(title: "Error", message: "Failed to create/update calendar event. Please check permissions.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
                return
            }
            
            // Если сохранение успешно, обновляем локальный массив.
            if let existingIndex = self.events.firstIndex(where: { $0.id == event.id }) {
                // Редактирование: заменяем старое на новое.
                self.events[existingIndex] = event
            } else {
                // Создание: добавляем новое.
                self.events.append(event)
            }
            
            self.saveAndRefresh()
        }
    }
    
    // MARK: - Cell Actions Handlers
    
    // Вызывается при нажатии кнопки удаления в ячейке.
    private func handleDelete(for event: WishEvent, at indexPath: IndexPath) {
        // Спрашиваем подтверждение у пользователя.
        let alert = UIAlertController(title: "Delete Event", message: "Are you sure you want to delete this event?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            // Если подтвердили — запускаем анимацию удаления.
            self?.animateDeletion(of: event, at: indexPath)
        }))
        present(alert, animated: true)
    }

    // Вызывается при нажатии кнопки Share.
    private func handleShare(for event: WishEvent) {
        let textToShare = "Let's work on this wish: \(event.title)!\nDescription: \(event.description)"
        // Стандартный системный контроллер "Поделиться".
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    // Сложная логика анимированного удаления.
    private func animateDeletion(of event: WishEvent, at indexPath: IndexPath) {
        // Проверяем, видна ли ячейка сейчас на экране.
        guard let cell = self.collectionView.cellForItem(at: indexPath) else {
            // Если ячейка за пределами экрана, просто удаляем данные и обновляем всё (без анимации).
            self.events.removeAll { $0.id == event.id }
            self.saveAndRefresh()
            return
        }

        // 1. Анимируем визуальное исчезновение ячейки (прозрачность + уменьшение).
        UIView.animate(withDuration: 0.3, animations: {
            cell.alpha = 0
            cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            // 2. Удаляем элемент из "сырого" массива данных.
            self.events.removeAll { $0.id == event.id }
            
            // 3. performBatchUpdates позволяет анимированно удалить строки/секции из CollectionView.
            self.collectionView.performBatchUpdates({
                // Запоминаем старые секции, чтобы понять, исчезла ли секция целиком.
                let oldSections = self.eventSections
                // Пересчитываем группировку уже БЕЗ удаленного элемента.
                self.groupEventsByDay()
                
                if self.eventSections.count < oldSections.count {
                    // Если количество секций уменьшилось — значит удаляем всю секцию целиком.
                    self.collectionView.deleteSections(IndexSet(integer: indexPath.section))
                } else {
                    // Иначе удаляем только конкретную ячейку в секции.
                    self.collectionView.deleteItems(at: [indexPath])
                }
                
                // Сохраняем изменения в память.
                self.saveEvents()
            })
        })
    }
    
    // MARK: - Data Logic
    
    // Группировка плоского списка событий по датам (для секций).
    private func groupEventsByDay() {
        // Сортируем по времени начала.
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        // Группируем. Ключом словаря становится начало дня (00:00:00) даты события.
        let groupedByDate = Dictionary(grouping: sortedEvents) { event in
            return Calendar.current.startOfDay(for: event.startDate)
        }
        
        // Превращаем словарь в массив EventSection и сортируем секции по дате.
        self.eventSections = groupedByDate.map { (date, events) in
            return EventSection(date: date, events: events)
        }.sorted { $0.date < $1.date }
    }
    
    private func saveAndRefresh() {
        saveEvents()
        groupEventsByDay()
        collectionView.reloadData()
    }
    
    // Сохранение в UserDefaults через JSONEncoder (т.к. WishEvent — Codable).
    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: Constants.eventsKey)
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    // Загрузка событий при старте.
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: Constants.eventsKey) else { return }
        do {
            events = try JSONDecoder().decode([WishEvent].self, from: data)
            groupEventsByDay()
            collectionView.reloadData()
        } catch {
            print("Failed to load events: \(error)")
        }
    }
    
    // Загрузка списка желаний (из другой части приложения).
    private func loadWishes() {
        if let loadedWishes = UserDefaults.standard.array(forKey: "myWishesArrayKey") as? [String] {
            self.wishes = loadedWishes
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
// Выносим реализацию протоколов в extension для чистоты кода.
extension WishCalendarViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Количество секций = количество дней с событиями.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return eventSections.count
    }
    
    // Количество ячеек в секции = количество событий в этот день.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return eventSections[section].events.count
    }
    
    // Настройка ячейки.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // DequeueReusableCell переиспользует ячейки для экономии памяти.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishEventCell.reuseId, for: indexPath) as? WishEventCell else {
            return UICollectionViewCell()
        }
        
        // Получаем событие для конкретной позиции.
        let event = eventSections[indexPath.section].events[indexPath.item]
        cell.configure(with: event)
        
        // ПРИВЯЗКА ЗАМЫКАНИЙ (CALLBACKS):
        // Когда кнопка на ячейке будет нажата, сработает код здесь, внутри контроллера.
        cell.onDelete = { [weak self] in
            self?.handleDelete(for: event, at: indexPath)
        }
        cell.onShare = { [weak self] in
            self?.handleShare(for: event)
        }
        
        return cell
    }
    
    // Настройка заголовка секции (Header).
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // Проверяем, что это именно Header.
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: EventSectionHeaderView.reuseId, for: indexPath) as? EventSectionHeaderView else {
            return UICollectionReusableView()
        }
        let section = eventSections[indexPath.section]
        header.configure(with: section.date)
        return header
    }
    
    // Размер заголовка.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: Constants.headerHeight)
    }
    
    // Обработка нажатия на саму ячейку (для редактирования).
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let eventToEdit = eventSections[indexPath.section].events[indexPath.item]
        showEventCreationScreen(with: eventToEdit)
    }
    
    // Размер ячейки: ширина экрана минус отступы.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 2 * Constants.cellHorizontalPadding
        return CGSize(width: width, height: Constants.cellHeight)
    }
    
    // Расстояние между ячейками по вертикали.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.cellVerticalSpacing
    }
}
