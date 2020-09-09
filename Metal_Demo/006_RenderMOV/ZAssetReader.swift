//
//  ZAssetReader.swift
//  006_RenderMOV
//
//  Created by zsq on 2020/9/9.
//  Copyright © 2020 zsq. All rights reserved.
//

import UIKit
import AVFoundation
class ZAssetReader: NSObject {

    //轨道
    var readerVideoTrackOutput: AVAssetReaderTrackOutput!
    //AVAssetReader可以从原始数据里获取解码后的音视频数据
    var assetReader: AVAssetReader!
    //视频地址
    var videoUrl: URL!
    //锁
    var lock: NSLock!
    
    convenience init(url: URL) {
        self.init()
        
        videoUrl = url
        lock = NSLock()
        
        setupAsset()
    }
    
    //Asset 相关设置
    func setupAsset() {
        //AVURLAssetPreferPreciseDurationAndTimingKey 默认为NO,YES表示提供精确的时长
        let inputOptions = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        
        //1. 创建AVURLAsset 是AVAsset 子类,用于从本地/远程URL初始化资源
        let inputAsset = AVURLAsset(url: videoUrl, options: inputOptions)
        
        //2.异步加载资源
        //对资源所需的键执行标准的异步载入操作,这样就可以访问资源的tracks属性时,就不会受到阻碍.
        inputAsset.loadValuesAsynchronously(forKeys: ["tracks"], completionHandler: {
            [weak self] in
            //开辟子线程并发队列异步函数来处理读取的inputAsset
            DispatchQueue.global().async {
                var error: NSError?
                //获取状态码.
                let tracksStatus = inputAsset.statusOfValue(forKey: "tracks", error: &error)
                //如果状态不等于成功加载,则返回并打印错误信息
                if tracksStatus != .loaded {
                    print(error!.localizedDescription)
                    return
                }
                
                //处理读取的inputAsset
                self?.processWithAsset(asset: inputAsset)
            }
        })
        
    }
    
    //处理获取到的asset
    func processWithAsset(asset: AVAsset) {
        //锁定
        lock.lock()
        print("processWithAsset")
        
        //1.创建AVAssetReader
        assetReader = try! AVAssetReader(asset: asset)
        
        //2.kCVPixelBufferPixelFormatTypeKey 像素格式.
        /*
         kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange : 420v
         kCVPixelFormatType_32BGRA : iOS在内部进行YUV至BGRA格式转换
         */
        let outputSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        
        /*3. 设置readerVideoTrackOutput
        assetReaderTrackOutputWithTrack:(AVAssetTrack *)track outputSettings:(nullable NSDictionary<NSString *, id> *)outputSettings
        参数1: 表示读取资源中什么信息
        参数2: 视频参数
        */
        readerVideoTrackOutput = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video).first!, outputSettings: outputSettings as [String : Any])
        
        //alwaysCopiesSampleData : 表示缓存区的数据输出之前是否会被复制.YES:输出总是从缓存区提供复制的数据,你可以自由的修改这些缓存区数据
        readerVideoTrackOutput.alwaysCopiesSampleData = false
        
        //4.为assetReader 填充输出
        assetReader.add(readerVideoTrackOutput)
        
        //5.assetReader 开始读取.并且判断是否开始.
        if !assetReader.startReading() {
            print("Error reading from file at URL: \(asset)")
        }
        
         //取消锁
        lock.unlock()
    }
    
    //读取Buffer 数据
    func readBuffer() -> CMSampleBuffer? {
        //锁定
        lock.lock()
        
        var sampleBuffer: CMSampleBuffer?
        //1.判断readerVideoTrackOutput 是否创建成功.
        if readerVideoTrackOutput != nil {
            
            //复制下一个缓存区的内容到sampleBufferRef
            sampleBuffer = readerVideoTrackOutput.copyNextSampleBuffer()
        } else {
            lock.unlock()
            return nil
        }
        
        //2.判断assetReader 并且status 是已经完成读取 则重新清空readerVideoTrackOutput/assetReader.并重新初始化它们
        if assetReader != nil && assetReader.status == AVAssetReader.Status.completed {
            print("customInit")
            readerVideoTrackOutput = nil
            assetReader = nil
            setupAsset()
        }
        
        lock.unlock()
        
        //3.返回读取到的sampleBufferRef 数据
        return sampleBuffer
    }
}
