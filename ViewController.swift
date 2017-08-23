//
//  ViewController.swift
//  sample
//
//  Created by 永田大祐 on 2016/12/18.
//  Copyright © 2016年 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate,UIGestureRecognizerDelegate {
    
    var input:AVCaptureDeviceInput!
    var output:AVCaptureVideoDataOutput!
    var session:AVCaptureSession!
    var camera:AVCaptureDevice!
    var imageView:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 画面タップでシャッターを切るための設定
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        // デリゲートをセット
        tapGesture.delegate = self;
        // Viewに追加.
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // スクリーン設定
        setupDisplay()
        // カメラの設定
        setupCamera()
    }
    
    // メモリ解放
    override func viewDidDisappear(_ animated: Bool) {
        // camera stop メモリ解放
        session.stopRunning()
        
        for output in session.outputs {
            session.removeOutput(output as? AVCaptureOutput)
        }
        
        for input in session.inputs {
            session.removeInput(input as? AVCaptureInput)
        }
        session = nil
        camera = nil
    }
    
    func setupDisplay(){
        //スクリーンの幅
        let screenWidth = UIScreen.main.bounds.size.width;
        //スクリーンの高さ
        let screenHeight = UIScreen.main.bounds.size.height;
        
        // プレビュー用のビューを生成
        imageView = UIImageView()
        imageView.frame = CGRect(x:0.0,y: 0.0, width:screenWidth,height: screenHeight)
        
    }
    
    func setupCamera(){
        // AVCaptureSession: キャプチャに関する入力と出力の管理
        session = AVCaptureSession()
        
        // sessionPreset: キャプチャ・クオリティの設定
        session.sessionPreset = AVCaptureSessionPresetHigh
        //        session.sessionPreset = AVCaptureSessionPresetPhoto
        //        session.sessionPreset = AVCaptureSessionPresetHigh
        //        session.sessionPreset = AVCaptureSessionPresetMedium
        //        session.sessionPreset = AVCaptureSessionPresetLow
        
        // AVCaptureDevice: カメラやマイクなどのデバイスを設定
        // 前面カメラを取得
        //AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
        // 背面カメラを取得
        //AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
        for caputureDevice: Any in AVCaptureDevice.devices() {
            // 背面カメラを取得
            // if (caputureDevice as AnyObject).position == AVCaptureDevicePosition.back {
            //   camera = caputureDevice as? AVCaptureDevice
            //}
            // 前面カメラを取得
            if (caputureDevice as AnyObject).position == AVCaptureDevicePosition.front {
                camera = caputureDevice as? AVCaptureDevice
            }
        }
        
        // カメラからの入力データ
        // swift 2.0
        do {
            input = try AVCaptureDeviceInput(device: camera) as AVCaptureDeviceInput
        } catch let error as NSError {
            print(error)
        }
        
        
        // 入力をセッションに追加
        if(session.canAddInput(input)) {
            session.addInput(input)
        }
        
        
        // AVCaptureStillImageOutput:静止画
        // AVCaptureMovieFileOutput:動画ファイル
        // AVCaptureAudioFileOutput:音声ファイル
        // AVCaptureVideoDataOutput:動画フレームデータ
        // AVCaptureAudioDataOutput:音声データ
        
        // AVCaptureVideoDataOutput:動画フレームデータを出力に設定
        output = AVCaptureVideoDataOutput()
        // 出力をセッションに追加
        if(session.canAddOutput(output)) {
            session.addOutput(output)
        }
        
        // ピクセルフォーマットを 32bit BGR + A とする
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        
        // フレームをキャプチャするためのサブスレッド用のシリアルキューを用意
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        output.alwaysDiscardsLateVideoFrames = true
        
        // ビデオ出力に接続
        _ = output.connection(withMediaType: AVMediaTypeVideo)
        
        session.startRunning()
        
        // deviceをロックして設定
        // swift 2.0
        do {
            try camera.lockForConfiguration()
            // フレームレート
            camera.activeVideoMinFrameDuration = CMTimeMake(1, 30)
            
            camera.unlockForConfiguration()
        } catch _ {
        }
    }
    
    
    // 新しいキャプチャの追加で呼ばれる
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // キャプチャしたsampleBufferからUIImageを作成
        let image:UIImage = self.captureImage(sampleBuffer: sampleBuffer)
        
        // 画像を画面に表示
        DispatchQueue.main.async { () -> Void in
            self.imageView.image = image
            self.imageView.image = smpleCamres.openCVSanple(image, cascade: "haarcascade_frontalface_alt.xml")
            
            if self.imageView != nil {
                //      self.takeStillPicture()
            }
            // UIImageViewをビューに追加
            self.view.addSubview(self.imageView)
        }
    }
    
    // sampleBufferからUIImageを作成
    func captureImage(sampleBuffer:CMSampleBuffer) -> UIImage{
        
        // Sampling Bufferから画像を取得
        let imageBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        
        
        // 色空間
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        // let bitsPerCompornent:Int = 8
        // swift 2.0
        let newContext:CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)!
        
        let imageRef:CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultImage
    }
    
    
    // タップイベント.
    func tapped(sender: UITapGestureRecognizer){
        print("タップ")
        takeStillPicture()
    }
    
    func takeStillPicture(){
        if var _:AVCaptureConnection? = output.connection(withMediaType: AVMediaTypeVideo){
            // アルバムに追加
            UIImageWriteToSavedPhotosAlbum(self.imageView.image!, self, nil, nil)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
