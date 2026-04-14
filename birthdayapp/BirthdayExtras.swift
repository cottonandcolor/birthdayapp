//
//  BirthdayExtras.swift
//  birthdayapp
//

import Foundation

extension Birthday {
    /// Western zodiac from month and day of birth.
    var zodiacSign: String {
        let cal = Calendar.current
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        switch (m, d) {
        case (3, 21...31), (4, 1...19): return "Aries"
        case (4, 20...30), (5, 1...20): return "Taurus"
        case (5, 21...31), (6, 1...20): return "Gemini"
        case (6, 21...30), (7, 1...22): return "Cancer"
        case (7, 23...31), (8, 1...22): return "Leo"
        case (8, 23...31), (9, 1...22): return "Virgo"
        case (9, 23...30), (10, 1...22): return "Libra"
        case (10, 23...31), (11, 1...21): return "Scorpio"
        case (11, 22...30), (12, 1...21): return "Sagittarius"
        case (12, 22...31), (1, 1...19): return "Capricorn"
        case (1, 20...31), (2, 1...18): return "Aquarius"
        default: return "Pisces"
        }
    }

    /// Next age they will turn (based on stored birth date).
    var nextAgeToTurn: Int {
        age + 1
    }

    /// Highlights round birthdays or nil if none.
    var milestoneMessage: String? {
        let n = nextAgeToTurn
        if [1, 10, 13, 16, 18, 21, 30, 40, 50, 60, 65, 70, 80, 90, 100].contains(n) {
            return "Turning \(n) — a milestone birthday!"
        }
        if n.isMultiple(of: 5), n >= 25, n < 100 {
            return "Turning \(n)"
        }
        return nil
    }

    var formattedGiftBudget: String? {
        guard giftBudget > 0 else { return nil }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: giftBudget))
    }
}

enum BirthdayEmojiPalette {
    static let options = ["🎂", "🎈", "🎁", "🥳", "🎉", "🧁", "🍰", "🎊", "💝", "⭐️", "🌟", "💐"]
}
