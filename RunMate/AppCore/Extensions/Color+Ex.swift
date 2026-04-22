//
//  Color+Ex.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64

        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (
                    255,
                    (int >> 8) * 17,
                    (int >> 4 & 0xF) * 17,
                    (int & 0xF) * 17
                )

            case 6: // RRGGBB (24-bit)
                (a, r, g, b) = (
                    255,
                    int >> 16 & 0xFF,
                    int >> 8 & 0xFF,
                    int & 0xFF
                )

            case 8: // RRGGBBAA (32-bit, Figma)
                (r, g, b, a) = (
                    int >> 24 & 0xFF,
                    int >> 16 & 0xFF,
                    int >> 8 & 0xFF,
                    int & 0xFF
                )

            default:
                (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Remove # prefix
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        // Validate length
        if cString.count != 6, cString.count != 8 {
            self.init(white: 0.5, alpha: 1.0) // Return gray for invalid length
            return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        if cString.count == 6 {
            // Handle 6-digit hex: #RRGGBB
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            // Handle 8-digit hex: #RRGGBBAA
            self.init(
                red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbValue & 0x000000FF) / 255.0
            )
        }
    }
}
