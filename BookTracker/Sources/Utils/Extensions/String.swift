//
//  String.swift
//  BookTracker
//
//  Created by 배성연 on 3/7/26.
//
import Foundation
import UIKit

extension String {
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var htmlToAttributedStringStrippingStyles: AttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            let ns = try NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )

            // 색/폰트 제거 (필요 시 문단 스타일도 정리)
            let fullRange = NSRange(location: 0, length: ns.length)
            ns.removeAttribute(.foregroundColor, range: fullRange)
            ns.removeAttribute(.backgroundColor, range: fullRange)
            ns.removeAttribute(.font, range: fullRange)

            // 문단 스타일에서 과격한 줄바꿈 설정을 완화 (선택 사항)
            ns.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
                guard let style = value as? NSParagraphStyle else { return }
                let m = style.mutableCopy() as! NSMutableParagraphStyle
                // SwiftUI의 lineLimit와 충돌 여지가 있는 설정들을 기본값에 가깝게 정리
                m.lineBreakMode = .byWordWrapping
                ns.addAttribute(.paragraphStyle, value: m, range: range)
            }

            return AttributedString(ns)
        } catch {
            return nil
        }
    }

    func htmlToAttributedString(color: UIColor) -> AttributedString {
        guard let data = data(using: .utf8) else { return AttributedString(self) }
        do {
            let ns = try NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            let fullRange = NSRange(location: 0, length: ns.length)
            ns.removeAttribute(.backgroundColor, range: fullRange)
            ns.removeAttribute(.link, range: fullRange)
            ns.addAttribute(.foregroundColor, value: color, range: fullRange)
            ns.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
                guard let style = value as? NSParagraphStyle else { return }
                let m = NSMutableParagraphStyle()
                m.alignment = style.alignment
                m.lineBreakMode = .byWordWrapping
                ns.addAttribute(.paragraphStyle, value: m, range: range)
            }
            return AttributedString(ns)
        } catch {
            return AttributedString(self)
        }
    }
}
