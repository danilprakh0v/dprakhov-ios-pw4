//
//  WishEvent.swift
//  dprakhovPW4
//
//  Created by Данил Прахов on 20.11.2025.
//

import Foundation

// Struct (структура) — идеальный выбор для хранения данных.
// Codable — это Swift протокол, который позволяет автоматически превращать
// эту структуру в набор байт (JSON) для сохранения в UserDefaults и обратно.
struct WishEvent: Codable {
    // Уникальный идентификатор.
    // Нужен, чтобы отличать события друг от друга,
    // даже если у них одинаковое название и время - (например, при удалении).
    let id: UUID
    
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
}
