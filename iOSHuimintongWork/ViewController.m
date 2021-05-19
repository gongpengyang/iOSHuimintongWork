//
//  ViewController.m
//  iOSHuimintongWork
//
//  Created by gongpengyang on 2021/5/19.
//

#import "ViewController.h"
#import "HKHTTPRequest.h"
#import "TestModel.h"
#import <YYModel/YYModel.h>
#import "SVProgressHUD.h"
#import "HKInterfaceConst.h"
#import "ViewController1.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self getNet];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self getNet];
    ViewController1 *vc = [[ViewController1 alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


/// eg.
- (void)getNet {
    
    __weak __typeof(&*self)weakSelf = self;
    
//    [SVProgressHUD show]; //loading 可以放到请求请求基类里面
    NSDictionary *para = @{@"type":@"1"};
    [HKHTTPRequest GET:kTest parameters:para cachePolicy:HKCachePolicyOnlyNetNoCache success:^(id  _Nonnull responseObject) {
//        [SVProgressHUD dismiss];
        TestModel *model = [TestModel yy_modelWithDictionary:responseObject];
        /// 刷新 UI
                
    } failure:^(NSError * _Nonnull error) {
//        [SVProgressHUD showWithStatus:@"失败!"];
    }];
}




@end

