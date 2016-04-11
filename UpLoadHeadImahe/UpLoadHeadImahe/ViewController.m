//
//  ViewController.m
//  UpLoadHeadImahe
//
//  Created by L on 16/4/11.
//  Copyright © 2016年 L. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AFNetworking.h"


#define AlertViewTag_NoAuthor 100

@interface ViewController ()<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIImageView *headImgView;
@property (nonatomic, strong) UIImagePickerController *picker;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"个人头像";
    
    [self loadControls];

    // Do any additional setup after loading the view, typically from a nib.
}
- (void)loadControls {
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onMoreClick:)];
    
    _headImgView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_headImgView];
    

}
-(void)onMoreClick:(id)sender{
    __block typeof (self) weak_self = self;

    _picker = [[UIImagePickerController alloc] init];
    _picker.delegate = self;
    _picker.allowsEditing = YES;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请选择图片"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
    UIAlertAction* fromPhotoAction = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault                                                                 handler:^(UIAlertAction * action) {
        weak_self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [weak_self presentViewController:weak_self.picker animated:YES completion:nil];
        NSLog(@"从相册选择");
    }];
    UIAlertAction* fromCameraAction = [UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault                                                             handler:^(UIAlertAction * action) {
        NSLog(@"相机");

        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        if(! [UIImagePickerController isSourceTypeAvailable:sourceType]){
            NSString *tips = @"相机不可用";
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无法使用相机" message:tips preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                NSLog(@"取消");
            }];
            UIAlertAction *otherAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSLog(@"确定");
            }];
            [alertController addAction:cancelAction];
            [alertController addAction:otherAction];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:_picker animated:YES completion:nil];
        if (![self getCameraRecordPermisson]) {
            NSString *tips = @"请在iPhone的“设置-隐私-相机”中允许访问相机";
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无法使用相机" message:tips preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                NSLog(@"取消");
            }];
            UIAlertAction *otherAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSLog(@"确定");
            }];
            [alertController addAction:cancelAction];
            [alertController addAction:otherAction];
            [self presentViewController:alertController animated:YES completion:nil];
 
        }
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:fromCameraAction];
    [alertController addAction:fromPhotoAction];
    [self presentViewController:alertController animated:YES completion:nil];

}

#pragma mark UIImagePickerControllerDelegate
//选择图或者拍照后的回调
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *orignalImage = [info objectForKey:UIImagePickerControllerOriginalImage];//原图
    UIImage *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];//编辑后的图片
    
    _headImgView.image = editedImage;
    
    // 拍照后保存原图片到相册中
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && orignalImage) {
        UIImageWriteToSavedPhotosAlbum(orignalImage, self, nil, NULL);
    }
    //上传照片
    [picker dismissViewControllerAnimated:YES completion:^{
        if (editedImage) {
            [self doUploadPhoto:editedImage];
        }
    }];
}
//上传头像
- (void)doUploadPhoto:(UIImage *)image{
    if (self.headImgView.image == nil) return;
    // 1.创建一个管理者
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    // 2.封装参数(这个字典只能放非文件参数)
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = @"123";
    params[@"age"] = @20;
    params[@"pwd"] = @"456";
    params[@"height"] = @1.55;
    
    // 2.发送一个请求
    NSString *url = @"http://192.168.15.172:8080/MJServer/upload";//上传地址
    [mgr POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSData *fileData = UIImageJPEGRepresentation(self.headImgView.image, 1.0);
        [formData appendPartWithFileData:fileData name:@"file" fileName:@"haha.jpg" mimeType:@"image/jpeg"];
        
        // 不是用这个方法来设置文件参数
        //        [formData appendPartWithFormData:fileData name:@"file"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"上传成功");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"上传失败");
    }];
    
    // 文件下载，文件比较大，断点续传技术：普遍所有的HTTP服务器都支持
    // 文件上传，文件比较大，断点续传技术：一般的HTTP服务器都不支持，常用的技术用的是Socket（TCP\IP、UDP）
}

//获得设备是否有访问相机权限
-(BOOL)getCameraRecordPermisson
{
    NSString * mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus  authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authorizationStatus == AVAuthorizationStatusRestricted|| authorizationStatus == AVAuthorizationStatusDenied)
    {
        return NO;
    }
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
