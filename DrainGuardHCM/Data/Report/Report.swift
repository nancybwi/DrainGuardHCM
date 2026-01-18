//
//  Report.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//
import Foundation

struct Report: Identifiable {
    let id: Int
    let title: String
    let submittedAt: Date
    let status: ReportStatus
}
