//
//  GenerateLoadData.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//


import Foundation


final class GenerateLoadData: DataPipelineTask<ImageResponse> {
    
    override func start() {
        if let image = pipeline.cachedImage(for: request) {
            
            let response = ImageResponse(container: image)
            
            if image.isPreview {
                send(value: response)
            } else {
                return send(value: response, isCompleted: true)
            }
        }
        
        guard let dataCache = pipeline.configuration.dataCache, pipeline.configuration.dataCacheOptions.storedItems.contains(.finalImage), request.cachePolicy != .reloadIgnoringCachedData else {
            return loadDecompressedImage()
        }

        operation = pipeline.configuration.dataCachingQueue.add { [weak self] in
            guard let self = self else { return }
            let key = self.request.makeCacheKeyForFinalImageData()
            let data = dataCache.cachedData(for: key)

            self.async {
                if let data = data {
                    self.decodeProcessedImageData(data)
                } else {
                    self.loadDecompressedImage()
                }
            }
        }
    }

    private func decodeProcessedImageData(_ data: Data) {
        guard !isDisposed else { return }

        let decoderContext = ImageDecodingContext(request: request, data: data, isCompleted: true, urlResponse: nil)
        guard let decoder = pipeline.configuration.makeImageDecoder(decoderContext) else {
            return loadDecompressedImage()
        }

        operation = pipeline.configuration.imageDecodingQueue.add { [weak self] in
            guard let self = self else { return }
            let response = decoder.decode(data, urlResponse: nil, isCompleted: true)
            
            self.async {
                if let response = response {
                    self.decompressProcessedImage(response, isCompleted: true)
                } else {
                    self.loadDecompressedImage()
                }
            }
        }
    }

    private func loadDecompressedImage() {
        dependency = pipeline.makeTaskProcessImage(for: request).subscribe(self) { [weak self] in
            self?.storeImageInDataCache($0)
            self?.decompressProcessedImage($0, isCompleted: $1)
        }
    }

    private func decompressProcessedImage(_ response: ImageResponse, isCompleted: Bool) {
        guard isDecompressionNeeded(for: response) else {
            pipeline.storeResponse(response.container, for: request)
            send(value: response, isCompleted: isCompleted)
            return
        }

        if isCompleted {
            operation?.cancel()
        } else if operation != nil {
            return
        }

        guard !isDisposed else { return }

        operation = pipeline.configuration.imageDecompressingQueue.add { [weak self] in
            guard let self = self else { return }

            let response = response.map { $0.map(ImageDecompression.decompress(image:)) } ?? response

            self.async {
                self.pipeline.storeResponse(response.container, for: self.request)
                self.send(value: response, isCompleted: isCompleted)
            }
        }
    }

    private func isDecompressionNeeded(for response: ImageResponse) -> Bool {
        return pipeline.configuration.isDecompressionEnabled &&
            ImageDecompression.isDecompressionNeeded(for: response.image) ?? false &&
            !(DataPipeLine.Configuration._isAnimatedImageDataEnabled)
    }

    
    private func storeImageInDataCache(_ response: ImageResponse) {
        guard let dataCache = pipeline.configuration.dataCache, pipeline.configuration.dataCacheOptions.storedItems.contains(.finalImage), !response.container.isPreview else {
            return
        }
        let context = ImageEncodingContext(request: request, image: response.image, urlResponse: response.urlResponse)
        let encoder = pipeline.configuration.makeImageEncoder(context)
        pipeline.configuration.imageEncodingQueue.addOperation { [request] in
            
            let encodedData = encoder.encode(response.container, context: context)

            guard let data = encodedData else { return }
            let key = request.makeCacheKeyForFinalImageData()
            dataCache.storeData(data, for: key) 
        }
    }
}
