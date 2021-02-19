//
//  GenerateProcess.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 29/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


final class GenerateProcess: DataPipelineTask<ImageResponse> {
    
    override func start() {
        
        assert(!request.processors.isEmpty)
        
        guard !isDisposed, !request.processors.isEmpty else { return }

        if let image = pipeline.cachedImage(for: request), !image.isPreview {
            return send(value: ImageResponse(container: image), isCompleted: true)
        }

        let processor: ImageProcessing
        var subRequest = request
        
        if pipeline.configuration.isDeduplicationEnabled {
            processor = request.processors.last!
            subRequest.processors = Array(request.processors.dropLast())
        } else {
            processor = ImageProcessors.Composition(request.processors)
            subRequest.processors = []
        }
        
        dependency = pipeline.makeTaskProcessImage(for: subRequest).subscribe(self) { [weak self] in
            self?.processImage($0, isCompleted: $1, processor: processor)
        }
    }

    private func processImage(_ response: ImageResponse, isCompleted: Bool, processor: ImageProcessing) {
        guard !(DataPipeLine.Configuration._isAnimatedImageDataEnabled) else {
            send(value: response, isCompleted: isCompleted)
            return
        }

        if isCompleted {
            operation?.cancel()
        } else if operation != nil {
            return
        }

        operation = pipeline.configuration.imageProcessingQueue.add { [weak self] in
            guard let self = self else { return }

            let context = ImageProcessingContext(request: self.request, response: response, isFinal: isCompleted)
            let response = response.map { processor.process($0, context: context) }

            self.async {
                guard let response = response else {
                    if isCompleted {
                        self.send(error: .processingFailed)
                    } 
                    return
                }
                self.send(value: response, isCompleted: isCompleted)
            }
        }
    }
}
