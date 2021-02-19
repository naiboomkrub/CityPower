//
//  ServiceFactory.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import CoreLocation
import ImageIO
import Photos


protocol ImageMetadataWritingService {
    func writeGpsData(from: CLLocation, to: LocalImageSource, completion: ((_ success: Bool) -> ())?)
}


final class ImageMetadataWritingServiceImpl: ImageMetadataWritingService {
    
    func writeGpsData(from location: CLLocation, to imageSource: LocalImageSource,
        completion: ((_ success: Bool) -> ())?) {
        
        DispatchQueue.global(qos: .background).async {
            let url = NSURL(fileURLWithPath: imageSource.path)
            let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            
            guard let source = CGImageSourceCreateWithURL(url, sourceOptions),
                let sourceType = CGImageSourceGetType(source),
                let destination = CGImageDestinationCreateWithURL(url, sourceType, 1, nil)
            else {
                completion?(false)
                return
            }
            
            let gpsMetadata = self.gpsMetadataDictionary(for: location) as [NSObject: AnyObject]
            
            let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                .flatMap { metadata in
                    var metadata = metadata as [NSObject: AnyObject]
                    metadata.merge(gpsMetadata) { current, _ in current }
                    return metadata
                }
                ?? gpsMetadata
            
            CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
            let success = CGImageDestinationFinalize(destination)
            
            completion?(success)
        }
    }
    
    private func gpsMetadataDictionary(for location: CLLocation?) -> [CFString: Any] {
        guard let coordinate = location?.coordinate else { return [:] }
        
        return [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: coordinate.latitude,
                kCGImagePropertyGPSLatitudeRef: coordinate.latitude < 0.0 ? "S" : "N",
                kCGImagePropertyGPSLongitude: coordinate.longitude,
                kCGImagePropertyGPSLongitudeRef: coordinate.longitude < 0.0 ? "W" : "E"
            ]
        ]
    }
}


struct ImageCroppingData {
    let originalImage: ImageSource
    var previewImage: ImageSource?
    var parameters: ImageCroppingParameters?
}

protocol ImageCroppingService: class {
    func canvasSize(completion: @escaping (CGSize) -> ())
    func imageWithParameters(completion: @escaping (ImageCroppingData) -> ())
    func croppedImage(previewImage: CGImage, completion: @escaping (CroppedImageSource) -> ())
    func croppedImageAspectRatio(completion: @escaping (Float) -> ())
    func setCroppingParameters(_ parameters: ImageCroppingParameters)
}


final class ImageCroppingServiceImpl: ImageCroppingService {
    
    private let originalImage: ImageSource
    private let previewImage: ImageSource?
    private var parameters: ImageCroppingParameters?
    private let canvasSize: CGSize
    private let imageStorage: ImageStorage
    
    init(image: ImageSource, canvasSize: CGSize, imageStorage: ImageStorage) {
        
        if let image = image as? CroppedImageSource {
            originalImage = image.originalImage
            parameters = image.croppingParameters
        } else {
            originalImage = image
        }
        
        previewImage = image
        
        self.imageStorage = imageStorage
        self.canvasSize = canvasSize
    }
    
    func canvasSize(completion: @escaping (CGSize) -> ()) {
        completion(canvasSize)
    }
    
    func imageWithParameters(completion: @escaping (ImageCroppingData) -> ()) {
        completion(
            ImageCroppingData(
                originalImage: originalImage,
                previewImage: previewImage,
                parameters: parameters
            )
        )
    }
    
    func croppedImage(previewImage: CGImage, completion: @escaping (CroppedImageSource) -> ()) {
        completion(
            CroppedImageSource(
                originalImage: originalImage,
                sourceSize: canvasSize,
                parameters: parameters,
                previewImage: previewImage,
                imageStorage: imageStorage
            )
        )
    }
    
    func croppedImageAspectRatio(completion: @escaping (Float) -> ()) {
        if let parameters = parameters, parameters.cropSize.height > 0 {
            completion(Float(parameters.cropSize.width / parameters.cropSize.height))
        } else {
            originalImage.imageSize { size in
                if let size = size {
                    completion(Float(size.width / size.height))
                } else {
                    completion(AspectRatio.defaultRatio.widthToHeightRatio())
                }
            }
        }
    }
    
    func setCroppingParameters(_ parameters: ImageCroppingParameters) {
            self.parameters = parameters
    }
    
}


protocol ServiceFactory: class {
    
    func cameraService(initialActiveCameraType: CameraType) -> CameraService
    func photoLibraryLatestPhotoProvider() -> PhotoLibraryLatestPhotoProvider
    func imageCroppingService(image: ImageSource, canvasSize: CGSize) -> ImageCroppingService
    func locationProvider() -> LocationProvider
    func imageMetadataWritingService() -> ImageMetadataWritingService
}


final class ServiceFactoryImpl: ServiceFactory {
    
    private let imageStorage: ImageStorage
    
    init(imageStorage: ImageStorage) {
        self.imageStorage = imageStorage
    }
    
    func cameraService(initialActiveCameraType: CameraType) -> CameraService {
        return CameraServiceImpl(
            initialActiveCameraType: initialActiveCameraType,
            imageStorage: imageStorage
        )
    }
    
    func photoLibraryLatestPhotoProvider() -> PhotoLibraryLatestPhotoProvider {
        return PhotoLibraryLatestPhotoProviderImpl()
    }
    
    func imageCroppingService(image: ImageSource, canvasSize: CGSize) -> ImageCroppingService {
        return ImageCroppingServiceImpl(
            image: image,
            canvasSize: canvasSize,
            imageStorage: imageStorage
        )
    }
    
    func locationProvider() -> LocationProvider {
        return LocationProviderImpl()
    }
    
    func imageMetadataWritingService() -> ImageMetadataWritingService {
        return ImageMetadataWritingServiceImpl()
    }
}
