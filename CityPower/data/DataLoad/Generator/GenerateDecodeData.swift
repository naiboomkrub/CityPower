//
//  GenerateDecodeData.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


final class GenerateDecodeImage: DataPipelineTask<ImageResponse> {
    
    private var decoder: ImageDecoding?

    override func start() {
        
        dependency = pipeline.makeTaskLoadImageData(for: request).subscribe(self) { [weak self] in
            self?.didReceiveData($0.0, urlResponse: $0.1, isCompleted: $1)
        }
    }

    private func didReceiveData(_ data: Data, urlResponse: URLResponse?, isCompleted: Bool) {
        
        guard isCompleted || pipeline.configuration.isProgressiveDecodingEnabled else { return }

        if !isCompleted && operation != nil { return }

        if isCompleted { operation?.cancel() }

        guard !data.isEmpty else {
            if isCompleted {
                send(error: .decodingFailed)
            }
            return
        }

        guard let decoder = decoder(data: data, urlResponse: urlResponse, isCompleted: isCompleted) else {
            if isCompleted {
                send(error: .decodingFailed)
            }
            return
        }

        operation = pipeline.configuration.imageDecodingQueue.add { [weak self] in
            guard let self = self else { return }

            let response = decoder.decode(data, urlResponse: urlResponse, isCompleted: isCompleted)
            
            self.async {
                if let response = response {
                    self.send(value: response, isCompleted: isCompleted)
                } else if isCompleted {
                    self.send(error: .decodingFailed)
                }
            }
        }
    }

    private func decoder(data: Data, urlResponse: URLResponse?, isCompleted: Bool) -> ImageDecoding? {
  
        if let decoder = self.decoder {
            return decoder
        }
        
        let decoderContext = ImageDecodingContext(request: request, data: data, isCompleted: isCompleted, urlResponse: urlResponse)
        let decoder = pipeline.configuration.makeImageDecoder(decoderContext)
        self.decoder = decoder
        
        return decoder
    }
}
