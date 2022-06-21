//
//  AR3DModel.swift
//  I18N
//
//  Created by 黄渊 on 2021/12/30.
//

import Foundation

/// 接口文档 http://logan.devops.xiaohongshu.com/desc/api?apiId=14631
public struct AR3DModel: Codable {

    let bizId: String

    let bizType: String

    let modelUsdzUrl: String

    let capaLink: String

    enum CodingKeys: String, CodingKey {
        case bizId = "biz_id"
        case bizType = "biz_type"
        case modelUsdzUrl = "model_usdz_url"
        case capaLink = "capa_link"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bizId = try values.decodeIfPresent(String.self, forKey: .bizId) ?? ""
        bizType = try values.decodeIfPresent(String.self, forKey: .bizType) ?? ""
        modelUsdzUrl = try values.decodeIfPresent(String.self, forKey: .modelUsdzUrl) ?? ""
        capaLink = try values.decodeIfPresent(String.self, forKey: .capaLink) ?? ""
    }
}
