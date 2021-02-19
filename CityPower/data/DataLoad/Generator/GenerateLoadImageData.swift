//
//  GenerateLoadImageData.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 29/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


final class GenerateLoadImageData: DataPipelineTask<(Data, URLResponse?)> {
    
    private var urlResponse: URLResponse?
    private var resumableData: ResumableData?
    private var resumedDataCount: Int64 = 0
    private lazy var data = Data()

    override func start() {
        
        guard let dataCache = pipeline.configuration.dataCache, pipeline.configuration.dataCacheOptions.storedItems.contains(.originalImageData), request.cachePolicy != .reloadIgnoringCachedData else {
            loadData()
            return
        }
        operation = pipeline.configuration.dataCachingQueue.add { [weak self] in
            self?.getCachedData(dataCache: dataCache)
        }
    }

    private func getCachedData(dataCache: DataCaching) {
        let key = request.makeCacheKeyForOriginalImageData()
        let data = dataCache.cachedData(for: key)
        
        async {
            if let data = data {
                self.send(value: (data, nil), isCompleted: true)
            } else {
                self.loadData()
            }
        }
    }

    private func loadData() {
        if let rateLimiter = pipeline.rateLimiter {

            rateLimiter.execute { [weak self] in
                guard let self = self, !self.isDisposed else {
                    return false
                }
                self.actuallyLoadData()
                return true
            }
        } else {
            actuallyLoadData()
        }
    }

    private func actuallyLoadData() {

        operation = pipeline.configuration.dataLoadingQueue.add { [weak self] finish in
            guard let self = self else {
                return finish()
            }
            self.async {
                self.loadImageData(finish: finish)
            }
        }
    }

    private func loadImageData(finish: @escaping () -> Void) {
        guard !isDisposed else {
            return finish()
        }

        var urlRequest = request.urlRequest

        if pipeline.configuration.isResumableDataEnabled,
           let resumableData = ResumableDataStorage.shared.removeResumableData(for: request, pipeline: pipeline) {

            resumableData.resume(request: &urlRequest)

            self.resumableData = resumableData
        }

        let dataTask = pipeline.configuration.dataLoader.loadData(
            with: urlRequest,
            didReceiveData: { [weak self] data, response in
                guard let self = self else { return }
                self.async {
                    self.dataTask(didReceiveData: data, response: response)
                }
            },
            completion: { [weak self] error in
                finish()
                guard let self = self else { return }
                self.async {
                    self.dataTaskDidFinish(error: error)
                }
            })

        onCancelled = { [weak self] in
            guard let self = self else { return }

            dataTask.cancel()
            finish()
            self.tryToSaveResumableData()
        }
    }

    private func dataTask(didReceiveData chunk: Data, response: URLResponse) {

        if urlResponse == nil {

            if let resumableData = resumableData, ResumableData.isResumedResponse(response) {
                data = resumableData.data
                resumedDataCount = Int64(resumableData.data.count)
            }
            resumableData = nil
        }

        data.append(chunk)
        urlResponse = response

        let progress = TaskProgress(completed: Int64(data.count), total: response.expectedContentLength + resumedDataCount)
        send(progress: progress)

        guard data.count < response.expectedContentLength else { return }

        send(value: (data, response))
    }

    private func dataTaskDidFinish(error: Swift.Error?) {
        if let error = error {
            tryToSaveResumableData()
            send(error: .dataLoadingFailed(error))
            return
        }

        guard !data.isEmpty else {
            send(error: .dataLoadingFailed(URLError(.unknown, userInfo: [:])))
            return
        }

        if let dataCache = pipeline.configuration.dataCache, pipeline.configuration.dataCacheOptions.storedItems.contains(.originalImageData) {
            let key = request.makeCacheKeyForOriginalImageData()
            dataCache.storeData(data, for: key)
        }

        send(value: (data, urlResponse), isCompleted: true)
    }

    private func tryToSaveResumableData() {

        if pipeline.configuration.isResumableDataEnabled,
           let response = urlResponse, !data.isEmpty,
           let resumableData = ResumableData(response: response, data: data) {
            ResumableDataStorage.shared.storeResumableData(resumableData, for: request, pipeline: pipeline)
        }
    }
}
