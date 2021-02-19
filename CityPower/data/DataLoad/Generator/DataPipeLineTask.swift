//
//  DataPipeLineTask.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 29/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


class DataPipelineTask<Value>: Generate<Value, DataPipeLine.Error> {
    let pipeline: DataPipeLine
    let request: DataRequest

    private let queue: DispatchQueue

    init(_ pipeline: DataPipeLine, _ request: DataRequest, _ queue: DispatchQueue) {
        self.pipeline = pipeline
        self.request = request
        self.queue = queue
    }

    func async(_ work: @escaping () -> Void) {
        queue.async(execute: work)
    }
}
