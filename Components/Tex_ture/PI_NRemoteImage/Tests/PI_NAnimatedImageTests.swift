//
//  PI_NAnimatedImageTests.swift
//  PI_NRemoteImageTests
//
//  Created by Garrett Moon on 9/16/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

import XCTest
import PI_NRemoteImage

class PI_NAnimatedImageTests: XCTestCase, PI_NRemoteImageManagerAlternateRepresentationProvider {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func timeoutInterval() -> TimeInterval {
        return 30
    }

    // MARK: - Animated Images
    func animatedWebPURL() -> URL? {
        return URL.init(string: "https://res.cloudinary.com/demo/image/upload/fl_awebp/bored_animation.webp")
    }
    
    func slowAnimatedGIFURL() -> URL? {
        return URL.init(string: "https://i.pinimg.com/originals/1d/65/00/1d650041ad356b248139800bc84b7bce.gif")
    }
    
    func nonAnimatedGIFURL() -> URL? {
        return URL.init(string: "http://ak-cache.legacy.net/legacy/images/fhlogo/7630fhlogo.gif")
    }
    
    func testMinimumFrameInterval() {
        let expectation =  self.expectation(description: "Result should be downloaded")
        let imageManager = PI_NRemoteImageManager.init(sessionConfiguration: nil, alternativeRepresentationProvider: self)
        imageManager.downloadImage(with: self.slowAnimatedGIFURL()!) { (result : PI_NRemoteImageManagerResult) in
            guard let animatedData = result.alternativeRepresentation as? Data else {
                XCTAssert(false, "alternativeRepresentation should be able to be coerced into data")
                return
            }
            
            guard let animatedImage = PI_NGIFAnimatedImage.init(animatedImageData: animatedData) else {
                XCTAssert(false, "could not create GIF image")
                return
            }
            
            XCTAssert(animatedImage.frameInterval == 12, "Frame interval should be 12 because each frame is 0.2 seconds long. 60 / 12 = 5; 1 / 5 of a second is 0.2.")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: self.timeoutInterval(), handler: nil)
    }
    
    func testWebpAnimatedImages() {
        let expectation =  self.expectation(description: "Result should be downloaded")
        let imageManager = PI_NRemoteImageManager.init(sessionConfiguration: nil, alternativeRepresentationProvider: self)
        imageManager.downloadImage(with: self.animatedWebPURL()!) { (result : PI_NRemoteImageManagerResult) in
            XCTAssertNotNil(result.alternativeRepresentation, "alternative representation should be non-nil.")
            XCTAssertNil(result.image, "image should not be returned")
            
            guard let animatedData = result.alternativeRepresentation as? Data else {
                XCTAssert(false, "alternativeRepresentation should be able to be coerced into data")
                return
            }
            
            guard let animatedImage = PI_NWebPAnimatedImage.init(animatedImageData: animatedData) else {
                XCTAssert(false, "could not create webp image")
                return
            }
            
            let frameCount = animatedImage.frameCount
            var totalDuration : CFTimeInterval = 0
            XCTAssert(frameCount > 1, "Frame count should be greater than 1")
            for frameIdx in 0 ..< frameCount {
                XCTAssertNotNil(animatedImage.image(at: UInt(frameIdx), cacheProvider: nil))
                totalDuration += animatedImage.duration(at: UInt(frameIdx))
            }
            XCTAssert(animatedImage.totalDuration > 0, "Total duration should be greater than 0")
            XCTAssertEqual(totalDuration, animatedImage.totalDuration, "Total duration should be equal to the sum of each frames duration")
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: self.timeoutInterval(), handler: nil)
    }
    
    func testGreatestCommonDivisor() {
        XCTAssert(PI_NAnimatedImage.greatestCommonDivisor(ofA: 1, andB: 1) == 1)
        XCTAssert(PI_NAnimatedImage.greatestCommonDivisor(ofA: 2, andB: 4) == 2)
        XCTAssert(PI_NAnimatedImage.greatestCommonDivisor(ofA: 4, andB: 2) == 2)
        XCTAssert(PI_NAnimatedImage.greatestCommonDivisor(ofA: 18, andB: 15) == 3)
        XCTAssert(PI_NAnimatedImage.greatestCommonDivisor(ofA: 42, andB: 56) == 14)
        XCTAssert(PI_NAnimatedImage.greatestCommonDivisor(ofA: 12, andB: 120) == 12)
    }
    
    func alternateRepresentation(with data: Data!, options: PI_NRemoteImageManagerDownloadOptions = []) -> Any! {
        guard let nsdata = data as? NSData else {
            return nil
        }
        if nsdata.pin_isAnimatedWebP() || nsdata.pin_isAnimatedGIF() {
            return data
        }
        return nil
    }
    
    func testIsAnimatedGIF() {
        let animatedExpectation =  self.expectation(description: "Animated image should be downloaded")
        let imageManager = PI_NRemoteImageManager.init(sessionConfiguration: nil, alternativeRepresentationProvider: self)
        imageManager.downloadImage(with: self.slowAnimatedGIFURL()!) { (result : PI_NRemoteImageManagerResult) in
            XCTAssert(result.image == nil)
            guard let animatedData = result.alternativeRepresentation as? NSData else {
                XCTAssert(false, "alternativeRepresentation should be able to be coerced into data")
                return
            }
            
            XCTAssert(animatedData.pin_isGIF() && animatedData.pin_isAnimatedGIF())
            
            animatedExpectation.fulfill()
        }
        
        let nonAnimatedExpectation = self.expectation(description: "Non animated image should be downloaded")
        imageManager.downloadImage(with: self.nonAnimatedGIFURL()!) { (result : PI_NRemoteImageManagerResult) in
            XCTAssert(result.image != nil && result.alternativeRepresentation == nil)
            nonAnimatedExpectation.fulfill()
        }
        self.waitForExpectations(timeout: self.timeoutInterval(), handler: nil)
    }
}