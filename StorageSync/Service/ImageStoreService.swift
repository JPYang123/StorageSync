import Foundation
import CloudKit
import UIKit

final class ImageStoreService {
    private let database: CKDatabase

    init(container: CKContainer = CKContainer.default()) {
        self.database = container.privateCloudDatabase
    }

    /// 上传 UIImage 到 CloudKit，并将其存储为 CKAsset
    func saveImage(_ image: UIImage,
                   recordType: String,
                   recordID: CKRecord.ID? = nil,
                   completion: @escaping (Result<CKRecord, Error>) -> Void) {
        // 将 UIImage 转为 JPEG 数据并写入临时文件
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversion",
                                        code: -1,
                                        userInfo: nil)))
            return
        }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try data.write(to: tempURL)
            // 创建或更新 CKRecord
            let record = recordID != nil
                ? CKRecord(recordType: recordType, recordID: recordID!)
                : CKRecord(recordType: recordType)
            record["asset"] = CKAsset(fileURL: tempURL)
            database.save(record) { savedRecord, error in
                // 上传完成后删除临时文件
                try? FileManager.default.removeItem(at: tempURL)
                if let error = error {
                    completion(.failure(error))
                } else if let savedRecord = savedRecord {
                    completion(.success(savedRecord))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// 从 CloudKit 下载图片
    func fetchImage(recordID: CKRecord.ID,
                    key: String = "asset",
                    completion: @escaping (Result<UIImage, Error>) -> Void) {
        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let record = record,
                  let asset = record[key] as? CKAsset,
                  let data = try? Data(contentsOf: asset.fileURL!),
                  let image = UIImage(data: data)
            else {
                completion(.failure(NSError(domain: "ImageFetch",
                                            code: -2,
                                            userInfo: nil)))
                return
            }
            completion(.success(image))
        }
    }
}
