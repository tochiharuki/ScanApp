//
//  FileConverter.swift
//  ScanApp
//

import UIKit
import PDFKit
import Foundation

struct FileConverter {
    
    /// JPG, PNG などの画像 → PDF へ変換（非同期版）
    static func convertImageToPDFAsync(inputURL: URL) async throws -> URL {
        // 出力先のPDFファイルURLを作成
        let outputURL = inputURL.deletingPathExtension().appendingPathExtension("pdf")
        
        // 画像を読み込む
        guard let image = UIImage(contentsOfFile: inputURL.path) else {
            throw NSError(domain: "ImageLoadError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "画像を読み込めませんでした"])
        }
        
        // PDFレンダラーで書き出す
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: image.size))
        try pdfRenderer.writePDF(to: outputURL) { context in
            context.beginPage()
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        return outputURL
    }
    
    /// PDF → 各ページを画像に変換
    static func convertPDFToImages(pdfURL: URL, outputDir: URL) throws -> [URL] {
        guard let pdfDoc = PDFDocument(url: pdfURL) else {
            throw NSError(domain: "PDFLoadError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "PDFを開けませんでした"])
        }
        
        var imageURLs: [URL] = []
        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            let imageURL = outputDir.appendingPathComponent("page_\(i + 1).jpg")
            if let data = image.jpegData(compressionQuality: 0.9) {
                try data.write(to: imageURL)
                imageURLs.append(imageURL)
            }
        }
        return imageURLs
    }
}