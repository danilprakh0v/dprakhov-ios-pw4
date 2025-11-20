//
//  CalendarManager.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import EventKit

// Протокол — это "контракт".
// Мы описываем, что умеет делать наш менеджер.
// Это полезно для тестов - (Mock-объекты) и чтобы скрыть лишнюю реализацию от других классов.
protocol CalendarManaging {
    func create(eventModel: WishEvent,
                completion: @escaping (Bool) -> Void)
}

final class CalendarManager: CalendarManaging {
    
    // Паттерн Singleton - (Одиночка).
    // Мы создаем единственный экземпляр этого класса на всё приложение.
    // shared — точка входа.
    // Доступ будет через CalendarManager.shared.
    static let shared = CalendarManager()
    
    // EKEventStore — это основной объект базы данных календаря iOS.
    // Через него мы читаем и записываем события.
    private let eventStore = EKEventStore()

    // Приватный init гарантирует, что никто не создаст второй экземпляр CalendarManager() вручную.
    private init() {}

    // Основной метод создания события.
    // @escaping (Bool) -> Void означает, что результат (успех или провал)
    // вернется когда-то в будущем, уже после того как эта функция завершит выполнение.
    func create(eventModel: WishEvent, completion: @escaping (Bool) -> Void) {
        
        // 1. Подготовка логики (Хендлер).
        // Мы заранее описываем, что делать, когда пользователь нажмет "Разрешить" или "Запретить".
        // Используем [weak self], чтобы избежать утечек памяти (retain cycle), в случае если менеджер будет уничтожен.
        let requestCompletionHandler: EKEventStoreRequestAccessCompletionHandler = { [weak self] (granted, error) in
            
            // Разворачиваем self и проверяем: дали ли доступ (granted) и нет ли ошибок.
            guard let self = self, granted, error == nil else {
                // Если доступа нет — сообщаем об ошибке.
                DispatchQueue.main.async { completion(false) }
                return
            }

            // 2. Создание события (если доступ получен).
            let event = EKEvent(eventStore: self.eventStore)
            
            // Перекладываем данные из нашей модели (WishEvent) в системную (EKEvent).
            event.title = eventModel.title
            event.startDate = eventModel.startDate
            event.endDate = eventModel.endDate
            event.notes = eventModel.description
            // Добавляем в календарь "по умолчанию" (тот, который у юзера стоит основным).
            event.calendar = self.eventStore.defaultCalendarForNewEvents

            do {
                // Попытка сохранения.
                // span: .thisEvent означает, что сохраняем только это событие - (актуально для повторяющихся).
                try self.eventStore.save(event, span: .thisEvent)
                
                // Успех!
                // Возвращаем true в главном потоке.
                DispatchQueue.main.async { completion(true) }
            } catch {
                // Если EventKit выбросил ошибку - (например, календарь только для чтения).
                print("Error saving event: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
        
        // Запрос доступа (Разные версии iOS).
        // Apple ужесточила правила в iOS 17.
        if #available(iOS 17.0, *) {
            // iOS 17+: Просим доступ ТОЛЬКО на запись (WriteOnly).
            // Это безопаснее, и пользователи охотнее соглашаются, так как мы не читаем их личные пункты календаря.
            eventStore.requestWriteOnlyAccessToEvents(completion: requestCompletionHandler)
        } else {
            // iOS 16 и старее: Старый метод запроса полного доступа (.event).
            // Сейчас он считается устаревшим (deprecated), но для поддержки старых iOS увы, необходим.
            eventStore.requestAccess(to: .event, completion: requestCompletionHandler)
        }
    }
}
