//
//  FKFlickrPhotosGetContactsPublicPhotos.m
//  FlickrKit
//
//  Generated by FKAPIBuilder on 12 Jun, 2013 at 17:19.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//
//  DO NOT MODIFY THIS FILE - IT IS MACHINE GENERATED


#import "FKFlickrPhotosGetContactsPublicPhotos.h" 

@implementation FKFlickrPhotosGetContactsPublicPhotos

- (BOOL) needsLogin {
    return NO;
}

- (BOOL) needsSigning {
    return NO;
}

- (FKPermission) requiredPerms {
    return -1;
}

- (NSString *) name {
    return @"flickr.photos.getContactsPublicPhotos";
}

- (BOOL) isValid:(NSError **)error {
    BOOL valid = YES;
	NSMutableString *errorDescription = [[NSMutableString alloc] initWithString:@"You are missing required params: "];
	if(!self.user_id) {
		valid = NO;
		[errorDescription appendString:@"'user_id', "];
	}

	if(error != NULL) {
		if(!valid) {	
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorInvalidArgs userInfo:userInfo];
		}
	}
    return valid;
}

- (NSDictionary *) args {
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
	if(self.user_id) {
		[args setValue:self.user_id forKey:@"user_id"];
	}
	if(self.count) {
		[args setValue:self.count forKey:@"count"];
	}
	if(self.just_friends) {
		[args setValue:self.just_friends forKey:@"just_friends"];
	}
	if(self.single_photo) {
		[args setValue:self.single_photo forKey:@"single_photo"];
	}
	if(self.include_self) {
		[args setValue:self.include_self forKey:@"include_self"];
	}
	if(self.extras) {
		[args setValue:self.extras forKey:@"extras"];
	}

    return [args copy];
}

- (NSString *) descriptionForError:(NSInteger)error {
    switch(error) {
		case FKFlickrPhotosGetContactsPublicPhotosError_UserNotFound:
			return @"User not found";
		case FKFlickrPhotosGetContactsPublicPhotosError_InvalidAPIKey:
			return @"Invalid API Key";
		case FKFlickrPhotosGetContactsPublicPhotosError_ServiceCurrentlyUnavailable:
			return @"Service currently unavailable";
		case FKFlickrPhotosGetContactsPublicPhotosError_FormatXXXNotFound:
			return @"Format \"xxx\" not found";
		case FKFlickrPhotosGetContactsPublicPhotosError_MethodXXXNotFound:
			return @"Method \"xxx\" not found";
		case FKFlickrPhotosGetContactsPublicPhotosError_InvalidSOAPEnvelope:
			return @"Invalid SOAP envelope";
		case FKFlickrPhotosGetContactsPublicPhotosError_InvalidXMLRPCMethodCall:
			return @"Invalid XML-RPC Method Call";
		case FKFlickrPhotosGetContactsPublicPhotosError_BadURLFound:
			return @"Bad URL found";
  
		default:
			return @"Unknown error code";
    }
}

@end