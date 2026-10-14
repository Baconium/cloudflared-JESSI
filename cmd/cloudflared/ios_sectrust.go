//go:build ios

package main

/*
#include <dlfcn.h>
#include <dispatch/dispatch.h>
#include <CoreFoundation/CoreFoundation.h>

CFArrayRef SecTrustCopyCertificateChain(const void *trust) {
	static CFArrayRef (*copyChain)(const void *);
	static CFIndex (*getCount)(const void *);
	static const void *(*getAtIndex)(const void *, CFIndex);
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		void *security = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);
		if (security) {
			copyChain = dlsym(security, "SecTrustCopyCertificateChain");
			getCount = dlsym(security, "SecTrustGetCertificateCount");
			getAtIndex = dlsym(security, "SecTrustGetCertificateAtIndex");
		}
	});
	if (copyChain) return copyChain(trust);
	if (!getCount || !getAtIndex) return NULL;
	CFIndex count = getCount(trust);
	CFMutableArrayRef chain = CFArrayCreateMutable(NULL, count, &kCFTypeArrayCallBacks);
	for (CFIndex i = 0; i < count; i++) {
		const void *cert = getAtIndex(trust, i);
		if (cert) CFArrayAppendValue(chain, cert);
	}
	return chain;
}
*/
import "C"
