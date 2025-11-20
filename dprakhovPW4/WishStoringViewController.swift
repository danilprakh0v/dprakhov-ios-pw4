//
//  WishStoringViewController.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import UIKit

// final модификатор доступа — если наследование не нужно, запрещаем его для оптимизации работы с классом.
final class WishStoringViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let wishesKey = "myWishesArrayKey"
        static let newWishTitle = "Make a Wish!"
        static let editWishTitle = "Edit Wish"
        static let navBarTitle = "My Wishlist"
        
        // Используем опциональное связывание шрифтов, чтобы в случае, если кастомный шрифт не загрузится, приложение не упало.
        static let largeTitleFont = UIFont(name: "Georgia-Bold", size: 34) ?? UIFont.boldSystemFont(ofSize: 34)
        static let titleFont = UIFont(name: "Georgia-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)
    }

    // MARK: - Properties
    
    // Цвет темы передается из предыдущего экрана, чтобы сохранить визуальный стиль.
    public var themeColor: UIColor = .systemGray6
    
    // Источник данных для таблицы.
    private var wishArray: [String] = []

    // MARK: - UI Elements
    
    // Создаем таблицу в стиле .insetGrouped - (с закругленными секциями, как в настройках iOS).
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.separatorStyle = .none // Убираем стандартные полоски-разделители.
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        table.showsVerticalScrollIndicator = false
        return table
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Настройка внешнего вида и загрузка данных.
        applyTheme()
        setupNavigationBar()
        setupLayout()
        loadWishes()
    }

    // MARK: - Theme and Style
    private func applyTheme() {
        view.backgroundColor = themeColor
        
        // Настройка NavigationBar, чтобы он соответствовал цвету фона и имел белый текст.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = themeColor
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white, .font: Constants.largeTitleFont]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: Constants.titleFont]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = Constants.navBarTitle
        // Включаем большие заголовки.
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Добавляем кнопку "+" через UIAction.
        let addAction = UIAction { [weak self] _ in
            // Вызываем алерт создания - (wish: nil, index: nil).
            self?.showWishAlert(isEditing: false, wish: nil, index: nil)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: addAction)
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        
        // Назначаем делегатов для управления таблицей.
        tableView.dataSource = self
        tableView.delegate = self
        
        // Регистрируем кастомную ячейку - (её код должен быть в WrittenWishCell.swift).
        tableView.register(WrittenWishCell.self, forCellReuseIdentifier: WrittenWishCell.reuseId)
        
        // Растягиваем таблицу на весь экран.
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Logic
    
    // Универсальный метод для показа AlertController.
    // Работает в двух режимах: Создание (new) и Редактирование (edit).
    private func showWishAlert(isEditing: Bool, wish: String?, index: Int?) {
        let title = isEditing ? Constants.editWishTitle : Constants.newWishTitle
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        // Добавляем текстовое поле.
        // Если редактируем — вставляем туда текущий текст желания.
        alert.addTextField { $0.text = wish }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let newWish = textField.text, !newWish.isEmpty else { return }
            
            if isEditing, let index = index {
                // --- Редактирование ---
                // Обновляем данные в массиве.
                self.wishArray[index] = newWish
                // Перезагружаем только одну строку для анимации.
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            } else {
                // --- Добавление ---
                // Добавляем в конец массива.
                self.wishArray.append(newWish)
                
                // Анимированно вставляем новую строку в конец таблицы.
                let newIndexPath = IndexPath(row: self.wishArray.count - 1, section: 0)
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                // Прокручиваем таблицу вниз к новому элементу.
                self.tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
            }
            // Сохраняем изменения в память телефона.
            self.saveWishes()
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Data Persistence (UserDefaults)
    
    // UserDefaults — простейшее хранилище (Key-Value).
    // Подходит для настроек и небольших массивов строк, как здесь.
    private func saveWishes() {
        UserDefaults.standard.set(wishArray, forKey: Constants.wishesKey)
    }
    
    private func loadWishes() {
        if let loadedWishes = UserDefaults.standard.array(forKey: Constants.wishesKey) as? [String] {
            wishArray = loadedWishes
            tableView.reloadData() // Перерисовываем таблицу после загрузки данных.
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension WishStoringViewController: UITableViewDataSource, UITableViewDelegate {
    // Количество строк = количеству элементов в массиве.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { wishArray.count }
    
    // Настройка каждой ячейки.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WrittenWishCell.reuseId, for: indexPath) as? WrittenWishCell else {
            return UITableViewCell()
        }
        
        // Нумерация: indexPath.row начинается с 0, поэтому добавляем 1.
        let wishText = wishArray[indexPath.row]
        let wishNumber = indexPath.row + 1
        
        // Конфигурируем ячейку данными и цветом темы.
        cell.configure(wishText: wishText, wishNumber: wishNumber, themeColor: themeColor)
        
        return cell
    }
    
    // Обработка нажатия на строку (для редактирования).
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Снимаем выделение (серый фон) с ячейки красиво.
        tableView.deselectRow(at: indexPath, animated: true)
        showWishAlert(isEditing: true, wish: wishArray[indexPath.row], index: indexPath.row)
    }
    
    // MARK: - Swipe Actions (Delete & Share)
    // Реализация свайпов влево.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Действие "Удалить".
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            
            // 1. Сначала удаляем данные из массива - (Модель).
            self.wishArray.remove(at: indexPath.row)
            self.saveWishes()
            
            // 2. Анимированное удаление строки из таблицы - (View).
            // performBatchUpdates позволяет объединить изменения.
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { finished in
                // 3. После удаления нужно обновить таблицу целиком,
                // чтобы пересчитать номера строк - (например, №3 должен стать №2).
                if finished {
                    self.tableView.reloadData()
                }
            })
            
            completion(true) // Сообщаем системе, что действие выполнено успешно.
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        // Действие "Поделиться".
        let shareAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            // Стандартный системный Share Sheet.
            let activityVC = UIActivityViewController(activityItems: [self.wishArray[indexPath.row]], applicationActivities: nil)
            self.present(activityVC, animated: true)
            completion(true)
        }
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = UIColor.systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
}
