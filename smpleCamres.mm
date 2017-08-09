//
//  smpleCamres.m
//  sampleCamera
//
//  Created by 永田大祐 on 2016/10/19.
//  Copyright © 2016年 永田大祐. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "sampleCamera-Bridging-Header.h"

#include <iostream>
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@implementation smpleCamres: NSObject
using namespace std;
using namespace cv;

+(UIImage *)openCVSanple:(UIImage *)image cascade:(NSString *)cascadeFilename {
    
    char argc;
    const int contour_index = argc = -1;
    
    UIImage* correctImage = image;
    UIGraphicsBeginImageContext(correctImage.size);
    [correctImage drawInRect:CGRectMake(0, 0, correctImage.size.width, correctImage.size.height)];
    correctImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //UIImageをcv::Matに変換
    cv::Mat mat;
    UIImageToMat(correctImage, mat);
    double scale = 4.0;
    cv::Mat gray, smallImg(cv::saturate_cast<int>(mat.rows/scale), cv::saturate_cast<int>(mat.cols/scale), CV_8UC1);
    
    // グレースケール画像に変換
    cv::cvtColor(mat, gray, CV_BGR2GRAY);
    
    // 処理時間短縮のために画像を縮小
    cv::Size patch_sie(100,100);
    cv::Point2f center(250.0,250.0);
    cv::Mat dst_img;
    
    cv::resize(gray, smallImg, smallImg.size(), 0, 0, cv::INTER_LINEAR);
    cv::equalizeHist( smallImg, smallImg);
    cv::CascadeClassifier face_cascade;
    
    // 分類器の読み込み
    NSString *path = [[NSBundle mainBundle] pathForResource:cascadeFilename
                                                     ofType:nil];
    std::string cascade_path = (char *)[path UTF8String];
    if(!face_cascade.load(cascade_path))
        return image;
    // マルチスケール（顔）探索xo
    std::vector<cv::Rect> faces;
    // 画像，出力矩形，縮小スケール，最低矩形数，（フラグ），最小矩形
    face_cascade.detectMultiScale(smallImg, faces,
                                  1.1, 2,
                                  CV_HAAR_SCALE_IMAGE,
                                  cv::Size(30, 30));
    
    // 結果の描画
    std::vector<cv::Rect>::const_iterator r = faces.begin();
    std::vector<cv::Rect>::const_iterator rr = faces.end();
    std::cout<<&r<<std::endl;
    std::cout<<&rr<<std::endl;
    std::cout <<"contour inde"<<contour_index<<std::endl;
    
    //輪郭の抽出
    std::vector<std::vector<cv::Point>>contours;
    std::vector<cv::Vec4i> hierarchy;
    double radius = 0.0;
    
				for(; r != rr; ++r) {
                    
                    cv::Point center;
                    center.x+= cv::saturate_cast<double>((r->x + r->width*0.5)*scale);
                    std::cout <<"num of "<< center.x<<std::endl;
                    center.y += cv::saturate_cast<double>((r->y + r->height*0.5)*scale);
                    std::cout <<"num of "<< center.y<<std::endl;
                    radius = cv::saturate_cast<double>((r->width + r->height)*0.25*scale);
                    cv::circle( mat, center, radius, cv::Scalar(255,255,0), 0, -1, 0 );
                    
                }
    std::cout <<"num of1 "<< center.x<<std::endl;
    std::cout <<"num of1 "<< center.y<<std::endl;
    std::cout <<"num of1 "<< radius<<std::endl;
    
    UIImage *result = MatToUIImage(mat);
    return result;
}

@end
