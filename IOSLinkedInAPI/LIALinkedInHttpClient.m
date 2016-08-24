// LIALinkedInHttpClient.m
//
// Copyright (c) 2013 Ancientprogramming
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
#import "LIALinkedInHttpClient.h"
#import "LIALinkedInAuthorizationViewController.h"
#import "NSString+LIAEncode.h"

@interface LIALinkedInHttpClient ()
@property(nonatomic, strong) LIALinkedInApplication *application;
@property(nonatomic, weak) UIViewController *presentingViewController;
@end

@implementation LIALinkedInHttpClient

+ (LIALinkedInHttpClient *)clientForApplication:(LIALinkedInApplication *)application {
  return [self clientForApplication:application presentingViewController:nil];
}

+ (LIALinkedInHttpClient *)clientForApplication:(LIALinkedInApplication *)application presentingViewController:viewController {
  LIALinkedInHttpClient *client = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.linkedin.com"]];
  client.application = application;
  client.presentingViewController = viewController;
  return client;
}

- (id)initWithBaseURL:(NSURL *)url {
  self = [super initWithBaseURL:url];
  if (self) {
    [self setResponseSerializer:[AFJSONResponseSerializer serializer]];
  }
  return self;
}

- (void)getAccessToken:(NSString *)authorizationCode success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
  NSString *accessTokenUrl = @"/oauth/v2/accessToken?grant_type=authorization_code&code=%@&redirect_uri=%@&client_id=%@&client_secret=%@";
  NSString *url = [NSString stringWithFormat:accessTokenUrl, authorizationCode, [self.application.redirectURL LIAEncode], self.application.clientId, self.application.clientSecret];

#ifdef isSessionManager // check if should use AFHTTPSessionManager or AFHTTPRequestOperationManager
    [self POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
#else
      [self POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
          
          success(responseObject);
          
      }  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
      }];
#endif

}

- (void)getAuthorizationCode:(void (^)(NSString *))success cancel:(void (^)(void))cancel failure:(void (^)(NSError *))failure {
  LIALinkedInAuthorizationViewController *authorizationViewController = [[LIALinkedInAuthorizationViewController alloc]
      initWithApplication:
          self.application
                  success:^(NSString *code) {
                    [self hideAuthenticateView];
                    if (success) {
                      success(code);
                    }
                  }
                   cancel:^{
                     [self hideAuthenticateView];
                     if (cancel) {
                       cancel();
                     }
                   } failure:^(NSError *error) {
        [self hideAuthenticateView];
        if (failure) {
          failure(error);
        }
      }];
  [self showAuthorizationView:authorizationViewController];
}

- (void)showAuthorizationView:(LIALinkedInAuthorizationViewController *)authorizationViewController {
  if (self.presentingViewController == nil)
    self.presentingViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    
  if (self.presentingViewController.presentedViewController != nil)
    self.presentingViewController = self.presentingViewController.presentedViewController;
    
  UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:authorizationViewController];

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
  }

  [self.presentingViewController presentViewController:nc animated:YES completion:nil];
}

- (void)hideAuthenticateView {
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
