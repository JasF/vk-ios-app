//
//  A_SDisplayNode.mm
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SDisplayNodeInternal.h>

#import <Async_DisplayKit/A_SDisplayNode+Ancestry.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/Async_DisplayKit+Debug.h>
#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>

#import <objc/runtime.h>

#import <Async_DisplayKit/_A_SAsyncTransaction.h>
#import <Async_DisplayKit/_A_SAsyncTransactionContainer+Private.h>
#import <Async_DisplayKit/_A_SCoreAnimationExtras.h>
#import <Async_DisplayKit/_A_SDisplayLayer.h>
#import <Async_DisplayKit/_A_SDisplayView.h>
#import <Async_DisplayKit/_A_SPendingState.h>
#import <Async_DisplayKit/_A_SScopeTimer.h>
#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SLayoutElementStylePrivate.h>
#import <Async_DisplayKit/A_SLayoutSpec.h>
#import <Async_DisplayKit/A_SLayoutSpecPrivate.h>
#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_SRunLoopQueue.h>
#import <Async_DisplayKit/A_SSignpost.h>
#import <Async_DisplayKit/A_STraitCollection.h>
#import <Async_DisplayKit/A_SWeakProxy.h>
#import <Async_DisplayKit/A_SResponderChainEnumerator.h>
#import <Async_DisplayKit/A_STipsController.h>

// Conditionally time these scopes to our debug ivars (only exist in debug/profile builds)
#if TIME_DISPLAYNODE_OPS
  #define TIME_SCOPED(outVar) A_SDN::ScopeTimer t(outVar)
#else
  #define TIME_SCOPED(outVar)
#endif

static A_SDisplayNodeNonFatalErrorBlock _nonFatalErrorBlock = nil;
NSInteger const A_SDefaultDrawingPriority = A_SDefaultTransactionPriority;

// Forward declare CALayerDelegate protocol as the iOS 10 SDK moves CALayerDelegate from an informal delegate to a protocol.
// We have to forward declare the protocol as this place otherwise it will not compile compiling with an Base SDK < iOS 10
@protocol CALayerDelegate;

@interface A_SDisplayNode () <UIGestureRecognizerDelegate, CALayerDelegate, _A_SDisplayLayerDelegate>

/**
 * See A_SDisplayNodeInternal.h for ivars
 */

@end

@implementation A_SDisplayNode

@dynamic layoutElementType;

@synthesize threadSafeBounds = _threadSafeBounds;

static std::atomic_bool storesUnflattenedLayouts = ATOMIC_VAR_INIT(NO);

BOOL A_SDisplayNodeSubclassOverridesSelector(Class subclass, SEL selector)
{
  return A_SSubclassOverridesSelector([A_SDisplayNode class], subclass, selector);
}

// For classes like A_STableNode, A_SCollectionNode, A_SScrollNode and similar - we have to be sure to set certain properties
// like setFrame: and setBackgroundColor: directly to the UIView and not apply it to the layer only.
BOOL A_SDisplayNodeNeedsSpecialPropertiesHandling(BOOL isSynchronous, BOOL isLayerBacked)
{
  return isSynchronous && !isLayerBacked;
}

_A_SPendingState *A_SDisplayNodeGetPendingState(A_SDisplayNode *node)
{
  A_SDN::MutexLocker l(node->__instanceLock__);
  _A_SPendingState *result = node->_pendingViewState;
  if (result == nil) {
    result = [[_A_SPendingState alloc] init];
    node->_pendingViewState = result;
  }
  return result;
}

/**
 *  Returns A_SDisplayNodeFlags for the given class/instance. instance MAY BE NIL.
 *
 *  @param c        the class, required
 *  @param instance the instance, which may be nil. (If so, the class is inspected instead)
 *  @remarks        The instance value is used only if we suspect the class may be dynamic (because it overloads 
 *                  +respondsToSelector: or -respondsToSelector.) In that case we use our "slow path", calling this 
 *                  method on each -init and passing the instance value. While this may seem like an unlikely scenario,
 *                  it turns our our own internal tests use a dynamic class, so it's worth capturing this edge case.
 *
 *  @return A_SDisplayNode flags.
 */
static struct A_SDisplayNodeFlags GetA_SDisplayNodeFlags(Class c, A_SDisplayNode *instance)
{
  A_SDisplayNodeCAssertNotNil(c, @"class is required");

  struct A_SDisplayNodeFlags flags = {0};

  flags.isInHierarchy = NO;
  flags.displaysAsynchronously = YES;
  flags.shouldAnimateSizeChanges = YES;
  flags.implementsDrawRect = ([c respondsToSelector:@selector(drawRect:withParameters:isCancelled:isRasterizing:)] ? 1 : 0);
  flags.implementsImageDisplay = ([c respondsToSelector:@selector(displayWithParameters:isCancelled:)] ? 1 : 0);
  if (instance) {
    flags.implementsDrawParameters = ([instance respondsToSelector:@selector(drawParametersForAsyncLayer:)] ? 1 : 0);
  } else {
    flags.implementsDrawParameters = ([c instancesRespondToSelector:@selector(drawParametersForAsyncLayer:)] ? 1 : 0);
  }
  
  
  return flags;
}

/**
 *  Returns A_SDisplayNodeMethodOverrides for the given class
 *
 *  @param c the class, required.
 *
 *  @return A_SDisplayNodeMethodOverrides.
 */
static A_SDisplayNodeMethodOverrides GetA_SDisplayNodeMethodOverrides(Class c)
{
  A_SDisplayNodeCAssertNotNil(c, @"class is required");
  
  A_SDisplayNodeMethodOverrides overrides = A_SDisplayNodeMethodOverrideNone;
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(touchesBegan:withEvent:))) {
    overrides |= A_SDisplayNodeMethodOverrideTouchesBegan;
  }
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(touchesMoved:withEvent:))) {
    overrides |= A_SDisplayNodeMethodOverrideTouchesMoved;
  }
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(touchesCancelled:withEvent:))) {
    overrides |= A_SDisplayNodeMethodOverrideTouchesCancelled;
  }
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(touchesEnded:withEvent:))) {
    overrides |= A_SDisplayNodeMethodOverrideTouchesEnded;
  }
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(layoutSpecThatFits:))) {
    overrides |= A_SDisplayNodeMethodOverrideLayoutSpecThatFits;
  }
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(calculateLayoutThatFits:)) ||
      A_SDisplayNodeSubclassOverridesSelector(c, @selector(calculateLayoutThatFits:
                                                                 restrictedToSize:
                                                             relativeToParentSize:))) {
    overrides |= A_SDisplayNodeMethodOverrideCalcLayoutThatFits;
  }
  if (A_SDisplayNodeSubclassOverridesSelector(c, @selector(calculateSizeThatFits:))) {
    overrides |= A_SDisplayNodeMethodOverrideCalcSizeThatFits;
  }

  return overrides;
}

+ (void)initialize
{
#if A_SDISPLAYNODE_A_SSERTIONS_ENABLED
  if (self != [A_SDisplayNode class]) {
    
    // Subclasses should never override these. Use unused to prevent warnings
    __unused NSString *classString = NSStringFromClass(self);
    
    A_SDisplayNodeAssert(!A_SDisplayNodeSubclassOverridesSelector(self, @selector(calculatedSize)), @"Subclass %@ must not override calculatedSize method.", classString);
    A_SDisplayNodeAssert(!A_SDisplayNodeSubclassOverridesSelector(self, @selector(calculatedLayout)), @"Subclass %@ must not override calculatedLayout method.", classString);
    A_SDisplayNodeAssert(!A_SDisplayNodeSubclassOverridesSelector(self, @selector(layoutThatFits:)), @"Subclass %@ must not override layoutThatFits: method. Instead override calculateLayoutThatFits:.", classString);
    A_SDisplayNodeAssert(!A_SDisplayNodeSubclassOverridesSelector(self, @selector(layoutThatFits:parentSize:)), @"Subclass %@ must not override layoutThatFits:parentSize method. Instead override calculateLayoutThatFits:.", classString);
    A_SDisplayNodeAssert(!A_SDisplayNodeSubclassOverridesSelector(self, @selector(recursivelyClearContents)), @"Subclass %@ must not override recursivelyClearContents method.", classString);
    A_SDisplayNodeAssert(!A_SDisplayNodeSubclassOverridesSelector(self, @selector(recursivelyClearPreloadedData)), @"Subclass %@ must not override recursivelyClearFetchedData method.", classString);
  } else {
    // Check if subnodes where modified during the creation of the layout
	  __block IMP originalLayoutSpecThatFitsIMP = A_SReplaceMethodWithBlock(self, @selector(_locked_layoutElementThatFits:), ^(A_SDisplayNode *_self, A_SSizeRange sizeRange) {
		  NSArray *oldSubnodes = _self.subnodes;
		  A_SLayoutSpec *layoutElement = ((A_SLayoutSpec *( *)(id, SEL, A_SSizeRange))originalLayoutSpecThatFitsIMP)(_self, @selector(_locked_layoutElementThatFits:), sizeRange);
		  NSArray *subnodes = _self.subnodes;
		  A_SDisplayNodeAssert(oldSubnodes.count == subnodes.count, @"Adding or removing nodes in layoutSpecBlock or layoutSpecThatFits: is not allowed and can cause unexpected behavior.");
		  for (NSInteger i = 0; i < oldSubnodes.count; i++) {
			  A_SDisplayNodeAssert(oldSubnodes[i] == subnodes[i], @"Adding or removing nodes in layoutSpecBlock or layoutSpecThatFits: is not allowed and can cause unexpected behavior.");
		  }
		  return layoutElement;
	  });
  }
#endif

  // Below we are pre-calculating values per-class and dynamically adding a method (_staticInitialize) to populate these values
  // when each instance is constructed. These values don't change for each class, so there is significant performance benefit
  // in doing it here. +initialize is guaranteed to be called before any instance method so it is safe to add this method here.
  // Note that we take care to detect if the class overrides +respondsToSelector: or -respondsToSelector and take the slow path
  // (recalculating for each instance) to make sure we are always correct.

  BOOL classOverridesRespondsToSelector = A_SSubclassOverridesClassSelector([NSObject class], self, @selector(respondsToSelector:));
  BOOL instancesOverrideRespondsToSelector = A_SSubclassOverridesSelector([NSObject class], self, @selector(respondsToSelector:));
  struct A_SDisplayNodeFlags flags = GetA_SDisplayNodeFlags(self, nil);
  A_SDisplayNodeMethodOverrides methodOverrides = GetA_SDisplayNodeMethodOverrides(self);
  
  __unused Class initializeSelf = self;

  IMP staticInitialize = imp_implementationWithBlock(^(A_SDisplayNode *node) {
    A_SDisplayNodeAssert(node.class == initializeSelf, @"Node class %@ does not have a matching _staticInitialize method; check to ensure [super initialize] is called within any custom +initialize implementations!  Overridden methods will not be called unless they are also implemented by superclass %@", node.class, initializeSelf);
    node->_flags = (classOverridesRespondsToSelector || instancesOverrideRespondsToSelector) ? GetA_SDisplayNodeFlags(node.class, node) : flags;
    node->_methodOverrides = (classOverridesRespondsToSelector) ? GetA_SDisplayNodeMethodOverrides(node.class) : methodOverrides;
  });

  class_replaceMethod(self, @selector(_staticInitialize), staticInitialize, "v:@");
}

+ (void)load
{
  // Ensure this value is cached on the main thread before needed in the background.
  A_SScreenScale();
}

+ (Class)viewClass
{
  return [_A_SDisplayView class];
}

+ (Class)layerClass
{
  return [_A_SDisplayLayer class];
}

#pragma mark - Lifecycle

- (void)_staticInitialize
{
  A_SDisplayNodeAssert(NO, @"_staticInitialize must be overridden");
}

- (void)_initializeInstance
{
  [self _staticInitialize];

#if A_SEVENTLOG_ENABLE
  _eventLog = [[A_SEventLog alloc] initWithObject:self];
#endif
  
  _viewClass = [self.class viewClass];
  _layerClass = [self.class layerClass];
  _contentsScaleForDisplay = A_SScreenScale();
  _drawingPriority = A_SDefaultDrawingPriority;
  
  _primitiveTraitCollection = A_SPrimitiveTraitCollectionMakeDefault();
  
  _calculatedDisplayNodeLayout = std::make_shared<A_SDisplayNodeLayout>();
  _pendingDisplayNodeLayout = nullptr;
  _layoutVersion = 1;
  
  _defaultLayoutTransitionDuration = 0.2;
  _defaultLayoutTransitionDelay = 0.0;
  _defaultLayoutTransitionOptions = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone;
  
  _flags.canClearContentsOfLayer = YES;
  _flags.canCallSetNeedsDisplayOfLayer = YES;
  A_SDisplayNodeLogEvent(self, @"init");
}

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  [self _initializeInstance];

  return self;
}

- (instancetype)initWithViewClass:(Class)viewClass
{
  if (!(self = [self init]))
    return nil;

  A_SDisplayNodeAssert([viewClass isSubclassOfClass:[UIView class]], @"should initialize with a subclass of UIView");

  _viewClass = viewClass;
  setFlag(Synchronous, ![viewClass isSubclassOfClass:[_A_SDisplayView class]]);

  return self;
}

- (instancetype)initWithLayerClass:(Class)layerClass
{
  if (!(self = [self init])) {
    return nil;
  }

  A_SDisplayNodeAssert([layerClass isSubclassOfClass:[CALayer class]], @"should initialize with a subclass of CALayer");

  _layerClass = layerClass;
  _flags.layerBacked = YES;
  setFlag(Synchronous, ![layerClass isSubclassOfClass:[_A_SDisplayLayer class]]);

  return self;
}

- (instancetype)initWithViewBlock:(A_SDisplayNodeViewBlock)viewBlock
{
  return [self initWithViewBlock:viewBlock didLoadBlock:nil];
}

- (instancetype)initWithViewBlock:(A_SDisplayNodeViewBlock)viewBlock didLoadBlock:(A_SDisplayNodeDidLoadBlock)didLoadBlock
{
  if (!(self = [self init])) {
    return nil;
  }

  [self setViewBlock:viewBlock];
  if (didLoadBlock != nil) {
    [self onDidLoad:didLoadBlock];
  }
  
  return self;
}

- (instancetype)initWithLayerBlock:(A_SDisplayNodeLayerBlock)layerBlock
{
  return [self initWithLayerBlock:layerBlock didLoadBlock:nil];
}

- (instancetype)initWithLayerBlock:(A_SDisplayNodeLayerBlock)layerBlock didLoadBlock:(A_SDisplayNodeDidLoadBlock)didLoadBlock
{
  if (!(self = [self init])) {
    return nil;
  }
  
  [self setLayerBlock:layerBlock];
  if (didLoadBlock != nil) {
    [self onDidLoad:didLoadBlock];
  }
  
  return self;
}

- (void)setViewBlock:(A_SDisplayNodeViewBlock)viewBlock
{
  A_SDisplayNodeAssertFalse(self.nodeLoaded);
  A_SDisplayNodeAssertNotNil(viewBlock, @"should initialize with a valid block that returns a UIView");

  _viewBlock = viewBlock;
  setFlag(Synchronous, YES);
}

- (void)setLayerBlock:(A_SDisplayNodeLayerBlock)layerBlock
{
  A_SDisplayNodeAssertFalse(self.nodeLoaded);
  A_SDisplayNodeAssertNotNil(layerBlock, @"should initialize with a valid block that returns a CALayer");

  _layerBlock = layerBlock;
  _flags.layerBacked = YES;
  setFlag(Synchronous, YES);
}

- (void)onDidLoad:(A_SDisplayNodeDidLoadBlock)body
{
  A_SDN::MutexLocker l(__instanceLock__);

  if ([self _locked_isNodeLoaded]) {
    A_SDisplayNodeAssertThreadAffinity(self);
    A_SDN::MutexUnlocker l(__instanceLock__);
    body(self);
  } else if (_onDidLoadBlocks == nil) {
    _onDidLoadBlocks = [NSMutableArray arrayWithObject:body];
  } else {
    [_onDidLoadBlocks addObject:body];
  }
}

- (void)dealloc
{
  _flags.isDeallocating = YES;

  // Synchronous nodes may not be able to call the hierarchy notifications, so only enforce for regular nodes.
  A_SDisplayNodeAssert(checkFlag(Synchronous) || !A_SInterfaceStateIncludesVisible(_interfaceState), @"Node should always be marked invisible before deallocating. Node: %@", self);
  
  self.asyncLayer.asyncDelegate = nil;
  _view.asyncdisplaykit_node = nil;
  _layer.asyncdisplaykit_node = nil;

  // Remove any subnodes so they lose their connection to the now deallocated parent.  This can happen
  // because subnodes do not retain their supernode, but subnodes can legitimately remain alive if another
  // thing outside the view hierarchy system (e.g. async display, controller code, etc). keeps a retained
  // reference to subnodes.

  for (A_SDisplayNode *subnode in _subnodes)
    [subnode _setSupernode:nil];

  // Trampoline any UIKit ivars' deallocation to main
  if (A_SDisplayNodeThreadIsMain() == NO) {
    [self _scheduleIvarsForMainDeallocation];
  }

  // TODO: Remove this? If supernode isn't already nil, this method isn't dealloc-safe anyway.
  [self _setSupernode:nil];
}

- (void)_scheduleIvarsForMainDeallocation
{
  NSValue *ivarsObj = [[self class] _ivarsThatMayNeedMainDeallocation];

  // Unwrap the ivar array
  unsigned int count = 0;
  // Will be unused if assertions are disabled.
  __unused int scanResult = sscanf(ivarsObj.objCType, "[%u^{objc_ivar}]", &count);
  A_SDisplayNodeAssert(scanResult == 1, @"Unexpected type in NSValue: %s", ivarsObj.objCType);
  Ivar ivars[count];
  [ivarsObj getValue:ivars];

  for (Ivar ivar : ivars) {
    id value = object_getIvar(self, ivar);
    if (value == nil) {
      continue;
    }
    
    if (A_SClassRequiresMainThreadDeallocation(object_getClass(value))) {
      as_log_debug(A_SMainThreadDeallocationLog(), "%@: Trampolining ivar '%s' value %@ for main deallocation.", self, ivar_getName(ivar), value);
      
      // Before scheduling the ivar for main thread deallocation we have clear out the ivar, otherwise we can run
      // into a race condition where the main queue is drained earlier than this node is deallocated and the ivar
      // is still deallocated on a background thread
      object_setIvar(self, ivar, nil);
      
      A_SPerformMainThreadDeallocation(&value);
    } else {
      as_log_debug(A_SMainThreadDeallocationLog(), "%@: Not trampolining ivar '%s' value %@.", self, ivar_getName(ivar), value);
    }
  }
}

/**
 * Returns an NSValue-wrapped array of all the ivars in this class or its superclasses
 * up through A_SDisplayNode, that we expect may need to be deallocated on main.
 * 
 * This method caches its results.
 *
 * Result is of type NSValue<[Ivar]>
 */
+ (NSValue * _Nonnull)_ivarsThatMayNeedMainDeallocation
{
  static NSCache<Class, NSValue *> *ivarsCache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    ivarsCache = [[NSCache alloc] init];
  });

  NSValue *result = [ivarsCache objectForKey:self];
  if (result != nil) {
    return result;
  }

  // Cache miss.
  unsigned int resultCount = 0;
  static const int kMaxDealloc2MainIvarsPerClassTree = 64;
  Ivar resultIvars[kMaxDealloc2MainIvarsPerClassTree];

  // Get superclass results first.
  Class c = class_getSuperclass(self);
  if (c != [NSObject class]) {
    NSValue *ivarsObj = [c _ivarsThatMayNeedMainDeallocation];
    // Unwrap the ivar array and append it to our working array
    unsigned int count = 0;
    // Will be unused if assertions are disabled.
    __unused int scanResult = sscanf(ivarsObj.objCType, "[%u^{objc_ivar}]", &count);
    A_SDisplayNodeAssert(scanResult == 1, @"Unexpected type in NSValue: %s", ivarsObj.objCType);
    A_SDisplayNodeCAssert(resultCount + count < kMaxDealloc2MainIvarsPerClassTree, @"More than %d dealloc2main ivars are not supported. Count: %d", kMaxDealloc2MainIvarsPerClassTree, resultCount + count);
    [ivarsObj getValue:resultIvars + resultCount];
    resultCount += count;
  }

  // Now gather ivars from this particular class.
  unsigned int allMyIvarsCount;
  Ivar *allMyIvars = class_copyIvarList(self, &allMyIvarsCount);

  for (NSUInteger i = 0; i < allMyIvarsCount; i++) {
    Ivar ivar = allMyIvars[i];
    const char *type = ivar_getTypeEncoding(ivar);

    if (type != NULL && strcmp(type, @encode(id)) == 0) {
      // If it's `id` we have to include it just in case.
      resultIvars[resultCount] = ivar;
      resultCount += 1;
      as_log_debug(A_SMainThreadDeallocationLog(), "%@: Marking ivar '%s' for possible main deallocation due to type id", self, ivar_getName(ivar));
    } else {
      // If it's an ivar with a static type, check the type.
      Class c = A_SGetClassFromType(type);
      if (A_SClassRequiresMainThreadDeallocation(c)) {
        resultIvars[resultCount] = ivar;
        resultCount += 1;
        as_log_debug(A_SMainThreadDeallocationLog(), "%@: Marking ivar '%s' for main deallocation due to class %@", self, ivar_getName(ivar), c);
      } else {
        as_log_debug(A_SMainThreadDeallocationLog(), "%@: Skipping ivar '%s' for main deallocation.", self, ivar_getName(ivar));
      }
    }
  }
  free(allMyIvars);

  // Encode the type (array of Ivars) into a string and wrap it in an NSValue
  char arrayType[32];
  snprintf(arrayType, 32, "[%u^{objc_ivar}]", resultCount);
  result = [NSValue valueWithBytes:resultIvars objCType:arrayType];

  [ivarsCache setObject:result forKey:self];
  return result;
}

#pragma mark - Loading

- (BOOL)_locked_shouldLoadViewOrLayer
{
  return !_flags.isDeallocating && !(_hierarchyState & A_SHierarchyStateRasterized);
}

- (UIView *)_locked_viewToLoad
{
  UIView *view = nil;
  if (_viewBlock) {
    view = _viewBlock();
    A_SDisplayNodeAssertNotNil(view, @"View block returned nil");
    A_SDisplayNodeAssert(![view isKindOfClass:[_A_SDisplayView class]], @"View block should return a synchronously displayed view");
    _viewBlock = nil;
    _viewClass = [view class];
  } else {
    view = [[_viewClass alloc] init];
  }
  
  // Special handling of wrapping UIKit components
  if (checkFlag(Synchronous)) {
    // UIImageView layers. More details on the flags
    if ([_viewClass isSubclassOfClass:[UIImageView class]]) {
      _flags.canClearContentsOfLayer = NO;
      _flags.canCallSetNeedsDisplayOfLayer = NO;
    }
      
    // UIActivityIndicator
    if ([_viewClass isSubclassOfClass:[UIActivityIndicatorView class]]
        || [_viewClass isSubclassOfClass:[UIVisualEffectView class]]) {
      self.opaque = NO;
    }
      
    // CAEAGLLayer
    if([[view.layer class] isSubclassOfClass:[CAEAGLLayer class]]){
      _flags.canClearContentsOfLayer = NO;
    }
  }

  return view;
}

- (CALayer *)_locked_layerToLoad
{
  A_SDisplayNodeAssert(_flags.layerBacked, @"_layerToLoad is only for layer-backed nodes");

  CALayer *layer = nil;
  if (_layerBlock) {
    layer = _layerBlock();
    A_SDisplayNodeAssertNotNil(layer, @"Layer block returned nil");
    A_SDisplayNodeAssert(![layer isKindOfClass:[_A_SDisplayLayer class]], @"Layer block should return a synchronously displayed layer");
    _layerBlock = nil;
    _layerClass = [layer class];
  } else {
    layer = [[_layerClass alloc] init];
  }

  return layer;
}

- (void)_locked_loadViewOrLayer
{
  if (_flags.layerBacked) {
    TIME_SCOPED(_debugTimeToCreateView);
    _layer = [self _locked_layerToLoad];
    static int A_SLayerDelegateAssociationKey;
    
    /**
     * CALayer's .delegate property is documented to be weak, but the implementation is actually assign.
     * Because our layer may survive longer than the node (e.g. if someone else retains it, or if the node
     * begins deallocation on a background thread and it waiting for the -dealloc call to reach main), the only
     * way to avoid a dangling pointer is to use a weak proxy.
     */
    A_SWeakProxy *instance = [A_SWeakProxy weakProxyWithTarget:self];
    _layer.delegate = (id<CALayerDelegate>)instance;
    objc_setAssociatedObject(_layer, &A_SLayerDelegateAssociationKey, instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  } else {
    TIME_SCOPED(_debugTimeToCreateView);
    _view = [self _locked_viewToLoad];
    _view.asyncdisplaykit_node = self;
    _layer = _view.layer;
  }
  _layer.asyncdisplaykit_node = self;
  
  self._locked_asyncLayer.asyncDelegate = self;
}

- (void)_didLoad
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  A_SDisplayNodeLogEvent(self, @"didLoad");
  as_log_verbose(A_SNodeLog(), "didLoad %@", self);
  TIME_SCOPED(_debugTimeForDidLoad);
  
  [self didLoad];
  
  __instanceLock__.lock();
  NSArray *onDidLoadBlocks = [_onDidLoadBlocks copy];
  _onDidLoadBlocks = nil;
  __instanceLock__.unlock();
  
  for (A_SDisplayNodeDidLoadBlock block in onDidLoadBlocks) {
    block(self);
  }
}

- (void)didLoad
{
  A_SDisplayNodeAssertMainThread();
  
  // Subclass hook
}

- (BOOL)isNodeLoaded
{
  if (A_SDisplayNodeThreadIsMain()) {
    // Because the view and layer can only be created and destroyed on Main, that is also the only thread
    // where the state of this property can change. As an optimization, we can avoid locking.
    return [self _locked_isNodeLoaded];
  } else {
    A_SDN::MutexLocker l(__instanceLock__);
    return [self _locked_isNodeLoaded];
  }
}

- (BOOL)_locked_isNodeLoaded
{
  return (_view != nil || (_layer != nil && _flags.layerBacked));
}

#pragma mark - Misc Setter / Getter

- (UIView *)view
{
  A_SDN::MutexLocker l(__instanceLock__);

  A_SDisplayNodeAssert(!_flags.layerBacked, @"Call to -view undefined on layer-backed nodes");
  BOOL isLayerBacked = _flags.layerBacked;
  if (isLayerBacked) {
    return nil;
  }

  if (_view != nil) {
    return _view;
  }

  if (![self _locked_shouldLoadViewOrLayer]) {
    return nil;
  }
  
  // Loading a view needs to happen on the main thread
  A_SDisplayNodeAssertMainThread();
  [self _locked_loadViewOrLayer];
  
  // FIXME: Ideally we'd call this as soon as the node receives -setNeedsLayout
  // but automatic subnode management would require us to modify the node tree
  // in the background on a loaded node, which isn't currently supported.
  if (_pendingViewState.hasSetNeedsLayout) {
    // Need to unlock before calling setNeedsLayout to avoid deadlocks.
    // MutexUnlocker will re-lock at the end of scope.
    A_SDN::MutexUnlocker u(__instanceLock__);
    [self __setNeedsLayout];
  }
  
  [self _locked_applyPendingStateToViewOrLayer];
  
  {
    // The following methods should not be called with a lock
    A_SDN::MutexUnlocker u(__instanceLock__);

    // No need for the lock as accessing the subviews or layers are always happening on main
    [self _addSubnodeViewsAndLayers];
    
    // A subclass hook should never be called with a lock
    [self _didLoad];
  }

  return _view;
}

- (CALayer *)layer
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (_layer != nil) {
    return _layer;
  }
  
  if (![self _locked_shouldLoadViewOrLayer]) {
    return nil;
  }
  
  // Loading a layer needs to happen on the main thread
  A_SDisplayNodeAssertMainThread();
  [self _locked_loadViewOrLayer];
  
  // FIXME: Ideally we'd call this as soon as the node receives -setNeedsLayout
  // but automatic subnode management would require us to modify the node tree
  // in the background on a loaded node, which isn't currently supported.
  if (_pendingViewState.hasSetNeedsLayout) {
    // Need to unlock before calling setNeedsLayout to avoid deadlocks.
    // MutexUnlocker will re-lock at the end of scope.
    A_SDN::MutexUnlocker u(__instanceLock__);
    [self __setNeedsLayout];
  }
  
  [self _locked_applyPendingStateToViewOrLayer];
  
  {
    // The following methods should not be called with a lock
    A_SDN::MutexUnlocker u(__instanceLock__);

    // No need for the lock as accessing the subviews or layers are always happening on main
    [self _addSubnodeViewsAndLayers];
    
    // A subclass hook should never be called with a lock
    [self _didLoad];
  }

  return _layer;
}

// Returns nil if the layer is not an _A_SDisplayLayer; will not create the layer if nil.
- (_A_SDisplayLayer *)asyncLayer
{
  A_SDN::MutexLocker l(__instanceLock__);
  return [self _locked_asyncLayer];
}

- (_A_SDisplayLayer *)_locked_asyncLayer
{
  return [_layer isKindOfClass:[_A_SDisplayLayer class]] ? (_A_SDisplayLayer *)_layer : nil;
}

- (BOOL)isSynchronous
{
  return checkFlag(Synchronous);
}

- (void)setLayerBacked:(BOOL)isLayerBacked
{
  // Only call this if assertions are enabled – it could be expensive.
  A_SDisplayNodeAssert(!isLayerBacked || self.supportsLayerBacking, @"Node %@ does not support layer backing.", self);

  A_SDN::MutexLocker l(__instanceLock__);
  if (_flags.layerBacked == isLayerBacked) {
    return;
  }
  
  if ([self _locked_isNodeLoaded]) {
    A_SDisplayNodeFailAssert(@"Cannot change layerBacked after view/layer has loaded.");
    return;
  }

  _flags.layerBacked = isLayerBacked;
}

- (BOOL)isLayerBacked
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.layerBacked;
}

- (BOOL)supportsLayerBacking
{
  A_SDN::MutexLocker l(__instanceLock__);
  return !checkFlag(Synchronous) && !_flags.viewEverHadAGestureRecognizerAttached && _viewClass == [_A_SDisplayView class] && _layerClass == [_A_SDisplayLayer class];
}

- (BOOL)shouldAnimateSizeChanges
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.shouldAnimateSizeChanges;
}

- (void)setShouldAnimateSizeChanges:(BOOL)shouldAnimateSizeChanges
{
  A_SDN::MutexLocker l(__instanceLock__);
  _flags.shouldAnimateSizeChanges = shouldAnimateSizeChanges;
}

- (CGRect)threadSafeBounds
{
  A_SDN::MutexLocker l(__instanceLock__);
  return [self _locked_threadSafeBounds];
}

- (CGRect)_locked_threadSafeBounds
{
  return _threadSafeBounds;
}

- (void)setThreadSafeBounds:(CGRect)newBounds
{
  A_SDN::MutexLocker l(__instanceLock__);
  _threadSafeBounds = newBounds;
}

- (void)nodeViewDidAddGestureRecognizer
{
  A_SDN::MutexLocker l(__instanceLock__);
  _flags.viewEverHadAGestureRecognizerAttached = YES;
}

#pragma mark <A_SDebugNameProvider>

- (NSString *)debugName
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _debugName;
}

- (void)setDebugName:(NSString *)debugName
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (!A_SObjectIsEqual(_debugName, debugName)) {
    _debugName = [debugName copy];
  }
}

#pragma mark - Layout

// At most a layoutSpecBlock or one of the three layout methods is overridden
#define __A_SDisplayNodeCheckForLayoutMethodOverrides \
    A_SDisplayNodeAssert(_layoutSpecBlock != NULL || \
    ((A_SDisplayNodeSubclassOverridesSelector(self.class, @selector(calculateSizeThatFits:)) ? 1 : 0) \
    + (A_SDisplayNodeSubclassOverridesSelector(self.class, @selector(layoutSpecThatFits:)) ? 1 : 0) \
    + (A_SDisplayNodeSubclassOverridesSelector(self.class, @selector(calculateLayoutThatFits:)) ? 1 : 0)) <= 1, \
    @"Subclass %@ must at least provide a layoutSpecBlock or override at most one of the three layout methods: calculateLayoutThatFits:, layoutSpecThatFits:, or calculateSizeThatFits:", NSStringFromClass(self.class))


#pragma mark <A_SLayoutElementTransition>

- (BOOL)canLayoutAsynchronous
{
  return !self.isNodeLoaded;
}

#pragma mark Layout Pass

- (void)__setNeedsLayout
{
  [self invalidateCalculatedLayout];
}

- (void)invalidateCalculatedLayout
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  _layoutVersion++;
  
  _unflattenedLayout = nil;

#if YOGA
  [self invalidateCalculatedYogaLayout];
#endif
}

- (void)__layout
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  BOOL loaded = NO;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    loaded = [self _locked_isNodeLoaded];
    CGRect bounds = _threadSafeBounds;
    
    if (CGRectEqualToRect(bounds, CGRectZero)) {
      // Performing layout on a zero-bounds view often results in frame calculations
      // with negative sizes after applying margins, which will cause
      // layoutThatFits: on subnodes to assert.
      as_log_debug(OS_LOG_DISABLED, "Warning: No size given for node before node was trying to layout itself: %@. Please provide a frame for the node.", self);
      return;
    }
    
    // If a current layout transition is in progress there is no need to do a measurement and layout pass in here as
    // this is supposed to happen within the layout transition process
    if (_transitionID != A_SLayoutElementContextInvalidTransitionID) {
      return;
    }

    as_activity_create_for_scope("-[A_SDisplayNode __layout]");

    // This method will confirm that the layout is up to date (and update if needed).
    // Importantly, it will also APPLY the layout to all of our subnodes if (unless parent is transitioning).
    __instanceLock__.unlock();
    [self _u_measureNodeWithBoundsIfNecessary:bounds];
    __instanceLock__.lock();

    [self _locked_layoutPlaceholderIfNecessary];
  }
  
  [self _layoutSublayouts];
  
  // Per API contract, `-layout` and `-layoutDidFinish` are called only if the node is loaded. 
  if (loaded) {
    A_SPerformBlockOnMainThread(^{
      [self layout];
      [self _layoutClipCornersIfNeeded];
      [self layoutDidFinish];
    });
  }
}

- (void)layoutDidFinish
{
  // Hook for subclasses
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  A_SDisplayNodeAssertTrue(self.isNodeLoaded);
}

#pragma mark Calculation

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize
{
  // Use a pthread specific to mark when this method is called re-entrant on same thread.
  // We only want one calculateLayout signpost interval per thread.
  // This is fast enough to do it unconditionally.
  auto key = A_SPthreadStaticKey(NULL);
  BOOL isRootCall = (pthread_getspecific(key) == NULL);
  as_activity_scope_verbose(as_activity_create("Calculate node layout", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT));
  as_log_verbose(A_SLayoutLog(), "Calculating layout for %@ sizeRange %@", self, NSStringFromA_SSizeRange(constrainedSize));
  if (isRootCall) {
    pthread_setspecific(key, kCFBooleanTrue);
    A_SSignpostStart(A_SSignpostCalculateLayout);
  }

  A_SSizeRange styleAndParentSize = A_SLayoutElementSizeResolve(self.style.size, parentSize);
  const A_SSizeRange resolvedRange = A_SSizeRangeIntersect(constrainedSize, styleAndParentSize);
  A_SLayout *result = [self calculateLayoutThatFits:resolvedRange];
  as_log_verbose(A_SLayoutLog(), "Calculated layout %@", result);

  if (isRootCall) {
    pthread_setspecific(key, NULL);
    A_SSignpostEnd(A_SSignpostCalculateLayout);
  }
  return result;
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  __A_SDisplayNodeCheckForLayoutMethodOverrides;

  A_SDN::MutexLocker l(__instanceLock__);

#if YOGA
  // There are several cases where Yoga could arrive here:
  // - This node is not in a Yoga tree: it has neither a yogaParent nor yogaChildren.
  // - This node is a Yoga tree root: it has no yogaParent, but has yogaChildren.
  // - This node is a Yoga tree node: it has both a yogaParent and yogaChildren.
  // - This node is a Yoga tree leaf: it has a yogaParent, but no yogaChidlren.
  YGNodeRef yogaNode = _style.yogaNode;
  BOOL hasYogaParent = (_yogaParent != nil);
  BOOL hasYogaChildren = (_yogaChildren.count > 0);
  BOOL usesYoga = (yogaNode != NULL && (hasYogaParent || hasYogaChildren));
  if (usesYoga) {
    // This node has some connection to a Yoga tree.
    if ([self shouldHaveYogaMeasureFunc] == NO) {
      // If we're a yoga root, tree node, or leaf with no measure func (e.g. spacer), then
      // initiate a new Yoga calculation pass from root.
      A_SDN::MutexUnlocker ul(__instanceLock__);
      as_activity_create_for_scope("Yoga layout calculation");
      if (self.yogaLayoutInProgress == NO) {
        A_SYogaLog("Calculating yoga layout from root %@, %@", self, NSStringFromA_SSizeRange(constrainedSize));
        [self calculateLayoutFromYogaRoot:constrainedSize];
      } else {
        A_SYogaLog("Reusing existing yoga layout %@", _yogaCalculatedLayout);
      }
      A_SDisplayNodeAssert(_yogaCalculatedLayout, @"Yoga node should have a non-nil layout at this stage: %@", self);
      return _yogaCalculatedLayout;
    } else {
      // If we're a yoga leaf node with custom measurement function, proceed with normal layout so layoutSpecs can run (e.g. A_SButtonNode).
      A_SYogaLog("PROCEEDING past Yoga check to calculate A_SLayout for: %@", self);
    }
  }
#endif /* YOGA */
  
  // Manual size calculation via calculateSizeThatFits:
  if (_layoutSpecBlock == NULL && (_methodOverrides & A_SDisplayNodeMethodOverrideLayoutSpecThatFits) == 0) {
    CGSize size = [self calculateSizeThatFits:constrainedSize.max];
    A_SDisplayNodeLogEvent(self, @"calculatedSize: %@", NSStringFromCGSize(size));
    return [A_SLayout layoutWithLayoutElement:self size:A_SSizeRangeClamp(constrainedSize, size) sublayouts:nil];
  }
  
  // Size calcualtion with layout elements
  BOOL measureLayoutSpec = _measurementOptions & A_SDisplayNodePerformanceMeasurementOptionLayoutSpec;
  if (measureLayoutSpec) {
    _layoutSpecNumberOfPasses++;
  }

  // Get layout element from the node
  id<A_SLayoutElement> layoutElement = [self _locked_layoutElementThatFits:constrainedSize];
#if A_SEnableVerboseLogging
  for (NSString *asciiLine in [[layoutElement asciiArtString] componentsSeparatedByString:@"\n"]) {
    as_log_verbose(A_SLayoutLog(), "%@", asciiLine);
  }
#endif


  // Certain properties are necessary to set on an element of type A_SLayoutSpec
  if (layoutElement.layoutElementType == A_SLayoutElementTypeLayoutSpec) {
    A_SLayoutSpec *layoutSpec = (A_SLayoutSpec *)layoutElement;
  
#if A_S_DEDUPE_LAYOUT_SPEC_TREE
    NSHashTable *duplicateElements = [layoutSpec findDuplicatedElementsInSubtree];
    if (duplicateElements.count > 0) {
      A_SDisplayNodeFailAssert(@"Node %@ returned a layout spec that contains the same elements in multiple positions. Elements: %@", self, duplicateElements);
      // Use an empty layout spec to avoid crashes
      layoutSpec = [[A_SLayoutSpec alloc] init];
    }
#endif

    A_SDisplayNodeAssert(layoutSpec.isMutable, @"Node %@ returned layout spec %@ that has already been used. Layout specs should always be regenerated.", self, layoutSpec);
    
    layoutSpec.isMutable = NO;
  }
  
  // Manually propagate the trait collection here so that any layoutSpec children of layoutSpec will get a traitCollection
  {
    A_SDN::SumScopeTimer t(_layoutSpecTotalTime, measureLayoutSpec);
    A_STraitCollectionPropagateDown(layoutElement, self.primitiveTraitCollection);
  }
  
  BOOL measureLayoutComputation = _measurementOptions & A_SDisplayNodePerformanceMeasurementOptionLayoutComputation;
  if (measureLayoutComputation) {
    _layoutComputationNumberOfPasses++;
  }

  // Layout element layout creation
  A_SLayout *layout = ({
    A_SDN::SumScopeTimer t(_layoutComputationTotalTime, measureLayoutComputation);
    [layoutElement layoutThatFits:constrainedSize];
  });
  A_SDisplayNodeAssertNotNil(layout, @"[A_SLayoutElement layoutThatFits:] should never return nil! %@, %@", self, layout);
    
  // Make sure layoutElementObject of the root layout is `self`, so that the flattened layout will be structurally correct.
  BOOL isFinalLayoutElement = (layout.layoutElement != self);
  if (isFinalLayoutElement) {
    layout.position = CGPointZero;
    layout = [A_SLayout layoutWithLayoutElement:self size:layout.size sublayouts:@[layout]];
  }
  A_SDisplayNodeLogEvent(self, @"computedLayout: %@", layout);

  // Return the (original) unflattened layout if it needs to be stored. The layout will be flattened later on (@see _locked_setCalculatedDisplayNodeLayout:).
  // Otherwise, flatten it right away.
  if (! [A_SDisplayNode shouldStoreUnflattenedLayouts]) {
    layout = [layout filteredNodeLayoutTree];
  }
  
  return layout;
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  __A_SDisplayNodeCheckForLayoutMethodOverrides;
  
  A_SDisplayNodeLogEvent(self, @"calculateSizeThatFits: with constrainedSize: %@", NSStringFromCGSize(constrainedSize));

  return A_SIsCGSizeValidForSize(constrainedSize) ? constrainedSize : CGSizeZero;
}

- (id<A_SLayoutElement>)_locked_layoutElementThatFits:(A_SSizeRange)constrainedSize
{
  __A_SDisplayNodeCheckForLayoutMethodOverrides;
  
  BOOL measureLayoutSpec = _measurementOptions & A_SDisplayNodePerformanceMeasurementOptionLayoutSpec;
  
  if (_layoutSpecBlock != NULL) {
    return ({
      A_SDN::MutexLocker l(__instanceLock__);
      A_SDN::SumScopeTimer t(_layoutSpecTotalTime, measureLayoutSpec);
      _layoutSpecBlock(self, constrainedSize);
    });
  } else {
    return ({
      A_SDN::SumScopeTimer t(_layoutSpecTotalTime, measureLayoutSpec);
      [self layoutSpecThatFits:constrainedSize];
    });
  }
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  __A_SDisplayNodeCheckForLayoutMethodOverrides;
  
  A_SDisplayNodeAssert(NO, @"-[A_SDisplayNode layoutSpecThatFits:] should never return an empty value. One way this is caused is by calling -[super layoutSpecThatFits:] which is not currently supported.");
  return [[A_SLayoutSpec alloc] init];
}

- (void)layout
{
  // Hook for subclasses
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  A_SDisplayNodeAssertTrue(self.isNodeLoaded);
  [_interfaceStateDelegate nodeDidLayout];
}

#pragma mark Layout Transition

- (void)_layoutTransitionMeasurementDidFinish
{
  // Hook for subclasses - No-Op in A_SDisplayNode
}

#pragma mark <_A_STransitionContextCompletionDelegate>

/**
 * After completeTransition: is called on the A_SContextTransitioning object in animateLayoutTransition: this
 * delegate method will be called that start the completion process of the transition
 */
- (void)transitionContext:(_A_STransitionContext *)context didComplete:(BOOL)didComplete
{
  A_SDisplayNodeAssertMainThread();

  [self didCompleteLayoutTransition:context];
  
  _pendingLayoutTransitionContext = nil;

  [self _pendingLayoutTransitionDidComplete];
}

- (void)calculatedLayoutDidChange
{
  // Subclass override
}

#pragma mark - Display

NSString * const A_SRenderingEngineDidDisplayScheduledNodesNotification = @"A_SRenderingEngineDidDisplayScheduledNodes";
NSString * const A_SRenderingEngineDidDisplayNodesScheduledBeforeTimestamp = @"A_SRenderingEngineDidDisplayNodesScheduledBeforeTimestamp";

- (BOOL)displaysAsynchronously
{
  A_SDN::MutexLocker l(__instanceLock__);
  return [self _locked_displaysAsynchronously];
}

/**
 * Core implementation of -displaysAsynchronously.
 */
- (BOOL)_locked_displaysAsynchronously
{
  return checkFlag(Synchronous) == NO && _flags.displaysAsynchronously;
}

- (void)setDisplaysAsynchronously:(BOOL)displaysAsynchronously
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  A_SDN::MutexLocker l(__instanceLock__);

  // Can't do this for synchronous nodes (using layers that are not _A_SDisplayLayer and so we can't control display prevention/cancel)
  if (checkFlag(Synchronous)) {
    return;
  }

  if (_flags.displaysAsynchronously == displaysAsynchronously) {
    return;
  }

  _flags.displaysAsynchronously = displaysAsynchronously;

  self._locked_asyncLayer.displaysAsynchronously = displaysAsynchronously;
}

- (BOOL)rasterizesSubtree
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.rasterizesSubtree;
}

- (void)enableSubtreeRasterization
{
  A_SDN::MutexLocker l(__instanceLock__);
  // Already rasterized from self.
  if (_flags.rasterizesSubtree) {
    return;
  }

  // If rasterized from above, bail.
  if (A_SHierarchyStateIncludesRasterized(_hierarchyState)) {
    A_SDisplayNodeFailAssert(@"Subnode of a rasterized node should not have redundant -enableSubtreeRasterization.");
    return;
  }

  // Ensure not loaded.
  if ([self _locked_isNodeLoaded]) {
    A_SDisplayNodeFailAssert(@"Cannot call %@ on loaded node: %@", NSStringFromSelector(_cmd), self);
    return;
  }

  // Ensure no loaded subnodes
  A_SDisplayNode *loadedSubnode = A_SDisplayNodeFindFirstSubnode(self, ^BOOL(A_SDisplayNode * _Nonnull node) {
    return node.nodeLoaded;
  });
  if (loadedSubnode != nil) {
      A_SDisplayNodeFailAssert(@"Cannot call %@ on node %@ with loaded subnode %@", NSStringFromSelector(_cmd), self, loadedSubnode);
      return;
  }

  _flags.rasterizesSubtree = YES;

  // Tell subnodes that now they're in a rasterized hierarchy (while holding lock!)
  for (A_SDisplayNode *subnode in _subnodes) {
    [subnode enterHierarchyState:A_SHierarchyStateRasterized];
  }
}

- (CGFloat)contentsScaleForDisplay
{
  A_SDN::MutexLocker l(__instanceLock__);

  return _contentsScaleForDisplay;
}

- (void)setContentsScaleForDisplay:(CGFloat)contentsScaleForDisplay
{
  A_SDN::MutexLocker l(__instanceLock__);

  if (_contentsScaleForDisplay == contentsScaleForDisplay) {
    return;
  }

  _contentsScaleForDisplay = contentsScaleForDisplay;
}

- (void)displayImmediately
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(!checkFlag(Synchronous), @"this method is designed for asynchronous mode only");

  [self.asyncLayer displayImmediately];
}

- (void)recursivelyDisplayImmediately
{
  for (A_SDisplayNode *child in self.subnodes) {
    [child recursivelyDisplayImmediately];
  }
  [self displayImmediately];
}

- (void)__setNeedsDisplay
{
  BOOL shouldScheduleForDisplay = NO;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    BOOL nowDisplay = A_SInterfaceStateIncludesDisplay(_interfaceState);
    // FIXME: This should not need to recursively display, so create a non-recursive variant.
    // The semantics of setNeedsDisplay (as defined by CALayer behavior) are not recursive.
    if (_layer != nil && !checkFlag(Synchronous) && nowDisplay && [self _implementsDisplay]) {
      shouldScheduleForDisplay = YES;
    }
  }
  
  if (shouldScheduleForDisplay) {
    [A_SDisplayNode scheduleNodeForRecursiveDisplay:self];
  }
}

+ (void)scheduleNodeForRecursiveDisplay:(A_SDisplayNode *)node
{
  static dispatch_once_t onceToken;
  static A_SRunLoopQueue<A_SDisplayNode *> *renderQueue;
  dispatch_once(&onceToken, ^{
    renderQueue = [[A_SRunLoopQueue<A_SDisplayNode *> alloc] initWithRunLoop:CFRunLoopGetMain()
                                                             retainObjects:NO
                                                                   handler:^(A_SDisplayNode * _Nonnull dequeuedItem, BOOL isQueueDrained) {
      [dequeuedItem _recursivelyTriggerDisplayAndBlock:NO];
      if (isQueueDrained) {
        CFTimeInterval timestamp = CACurrentMediaTime();
        [[NSNotificationCenter defaultCenter] postNotificationName:A_SRenderingEngineDidDisplayScheduledNodesNotification
                                                            object:nil
                                                          userInfo:@{A_SRenderingEngineDidDisplayNodesScheduledBeforeTimestamp: @(timestamp)}];
      }
    }];
  });

  as_log_verbose(A_SDisplayLog(), "%s %@", sel_getName(_cmd), node);
  [renderQueue enqueue:node];
}

/// Helper method to summarize whether or not the node run through the display process
- (BOOL)_implementsDisplay
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  return _flags.implementsDrawRect || _flags.implementsImageDisplay || _flags.rasterizesSubtree;
}

// Track that a node will be displayed as part of the current node hierarchy.
// The node sending the message should usually be passed as the parameter, similar to the delegation pattern.
- (void)_pendingNodeWillDisplay:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertMainThread();

  // No lock needed as _pendingDisplayNodes is main thread only
  if (!_pendingDisplayNodes) {
    _pendingDisplayNodes = [[A_SWeakSet alloc] init];
  }

  [_pendingDisplayNodes addObject:node];
}

// Notify that a node that was pending display finished
// The node sending the message should usually be passed as the parameter, similar to the delegation pattern.
- (void)_pendingNodeDidDisplay:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertMainThread();

  // No lock for _pendingDisplayNodes needed as it's main thread only
  [_pendingDisplayNodes removeObject:node];

  if (_pendingDisplayNodes.isEmpty) {
    
    [self hierarchyDisplayDidFinish];
    BOOL placeholderShouldPersist = [self placeholderShouldPersist];

    __instanceLock__.lock();
    if (_placeholderLayer.superlayer && !placeholderShouldPersist) {
      void (^cleanupBlock)() = ^{
        [_placeholderLayer removeFromSuperlayer];
      };

      if (_placeholderFadeDuration > 0.0 && A_SInterfaceStateIncludesVisible(self.interfaceState)) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:cleanupBlock];
        [CATransaction setAnimationDuration:_placeholderFadeDuration];
        _placeholderLayer.opacity = 0.0;
        [CATransaction commit];
      } else {
        cleanupBlock();
      }
    }
    __instanceLock__.unlock();
  }
}

- (void)hierarchyDisplayDidFinish
{
  // Subclass hook
}

// Helper method to determine if it's safe to call setNeedsDisplay on a layer without throwing away the content.
// For details look at the comment on the canCallSetNeedsDisplayOfLayer flag
- (BOOL)_canCallSetNeedsDisplayOfLayer
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.canCallSetNeedsDisplayOfLayer;
}

void recursivelyTriggerDisplayForLayer(CALayer *layer, BOOL shouldBlock)
{
  // This recursion must handle layers in various states:
  // 1. Just added to hierarchy, CA hasn't yet called -display
  // 2. Previously in a hierarchy (such as a working window owned by an Intelligent Preloading class, like A_STableView / A_SCollectionView / A_SViewController)
  // 3. Has no content to display at all
  // Specifically for case 1), we need to explicitly trigger a -display call now.
  // Otherwise, there is no opportunity to block the main thread after CoreAnimation's transaction commit
  // (even a runloop observer at a late call order will not stop the next frame from compositing, showing placeholders).
  
  A_SDisplayNode *node = [layer asyncdisplaykit_node];
  
  if (node.isSynchronous && [node _canCallSetNeedsDisplayOfLayer]) {
    // Layers for UIKit components that are wrapped within a node needs to be set to be displayed as the contents of
    // the layer get's cleared and would not be recreated otherwise.
    // We do not call this for _A_SDisplayLayer as an optimization.
    [layer setNeedsDisplay];
  }
  
  if ([node _implementsDisplay]) {
    // For layers that do get displayed here, this immediately kicks off the work on the concurrent -[_A_SDisplayLayer displayQueue].
    // At the same time, it creates an associated _A_SAsyncTransaction, which we can use to block on display completion.  See A_SDisplayNode+AsyncDisplay.mm.
    [layer displayIfNeeded];
  }
  
  // Kick off the recursion first, so that all necessary display calls are sent and the displayQueue is full of parallelizable work.
  // NOTE: The docs report that `sublayers` returns a copy but it actually doesn't.
  for (CALayer *sublayer in [layer.sublayers copy]) {
    recursivelyTriggerDisplayForLayer(sublayer, shouldBlock);
  }
  
  if (shouldBlock) {
    // As the recursion unwinds, verify each transaction is complete and block if it is not.
    // While blocking on one transaction, others may be completing concurrently, so it doesn't matter which blocks first.
    BOOL waitUntilComplete = (!node.shouldBypassEnsureDisplay);
    if (waitUntilComplete) {
      for (_A_SAsyncTransaction *transaction in [layer.asyncdisplaykit_asyncLayerTransactions copy]) {
        // Even if none of the layers have had a chance to start display earlier, they will still be allowed to saturate a multicore CPU while blocking main.
        // This significantly reduces time on the main thread relative to UIKit.
        [transaction waitUntilComplete];
      }
    }
  }
}

- (void)_recursivelyTriggerDisplayAndBlock:(BOOL)shouldBlock
{
  A_SDisplayNodeAssertMainThread();
  
  CALayer *layer = self.layer;
  // -layoutIfNeeded is recursive, and even walks up to superlayers to check if they need layout,
  // so we should call it outside of starting the recursion below.  If our own layer is not marked
  // as dirty, we can assume layout has run on this subtree before.
  if ([layer needsLayout]) {
    [layer layoutIfNeeded];
  }
  recursivelyTriggerDisplayForLayer(layer, shouldBlock);
}

- (void)recursivelyEnsureDisplaySynchronously:(BOOL)synchronously
{
  [self _recursivelyTriggerDisplayAndBlock:synchronously];
}

- (void)setShouldBypassEnsureDisplay:(BOOL)shouldBypassEnsureDisplay
{
  A_SDN::MutexLocker l(__instanceLock__);
  _flags.shouldBypassEnsureDisplay = shouldBypassEnsureDisplay;
}

- (BOOL)shouldBypassEnsureDisplay
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.shouldBypassEnsureDisplay;
}

- (void)setNeedsDisplayAtScale:(CGFloat)contentsScale
{
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if (contentsScale == _contentsScaleForDisplay) {
      return;
    }
    
    _contentsScaleForDisplay = contentsScale;
  }

  [self setNeedsDisplay];
}

- (void)recursivelySetNeedsDisplayAtScale:(CGFloat)contentsScale
{
  A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode *node) {
    [node setNeedsDisplayAtScale:contentsScale];
  });
}

- (void)_layoutClipCornersIfNeeded
{
  A_SDisplayNodeAssertMainThread();
  if (_clipCornerLayers[0] == nil) {
    return;
  }
  
  CGSize boundsSize = self.bounds.size;
  for (int idx = 0; idx < 4; idx++) {
    BOOL isTop   = (idx == 0 || idx == 1);
    BOOL isRight = (idx == 1 || idx == 2);
    if (_clipCornerLayers[idx]) {
      // Note the Core Animation coordinates are reversed for y; 0 is at the bottom.
      _clipCornerLayers[idx].position = CGPointMake(isRight ? boundsSize.width : 0.0, isTop ? boundsSize.height : 0.0);
      [_layer addSublayer:_clipCornerLayers[idx]];
    }
  }
}

- (void)_updateClipCornerLayerContentsWithRadius:(CGFloat)radius backgroundColor:(UIColor *)backgroundColor
{
  A_SPerformBlockOnMainThread(^{
    for (int idx = 0; idx < 4; idx++) {
      // Layers are, in order: Top Left, Top Right, Bottom Right, Bottom Left.
      // anchorPoint is Bottom Left at 0,0 and Top Right at 1,1.
      BOOL isTop   = (idx == 0 || idx == 1);
      BOOL isRight = (idx == 1 || idx == 2);
      
      CGSize size = CGSizeMake(radius + 1, radius + 1);
      UIGraphicsBeginImageContextWithOptions(size, NO, self.contentsScaleForDisplay);
      
      CGContextRef ctx = UIGraphicsGetCurrentContext();
      if (isRight == YES) {
        CGContextTranslateCTM(ctx, -radius + 1, 0);
      }
      if (isTop == YES) {
        CGContextTranslateCTM(ctx, 0, -radius + 1);
      }
      UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius * 2, radius * 2) cornerRadius:radius];
      [roundedRect setUsesEvenOddFillRule:YES];
      [roundedRect appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-1, -1, radius * 2 + 1, radius * 2 + 1)]];
      [backgroundColor setFill];
      [roundedRect fill];
      
      // No lock needed, as _clipCornerLayers is only modified on the main thread.
      CALayer *clipCornerLayer = _clipCornerLayers[idx];
      clipCornerLayer.contents = (id)(UIGraphicsGetImageFromCurrentImageContext().CGImage);
      clipCornerLayer.bounds = CGRectMake(0.0, 0.0, size.width, size.height);
      clipCornerLayer.anchorPoint = CGPointMake(isRight ? 1.0 : 0.0, isTop ? 1.0 : 0.0);

      UIGraphicsEndImageContext();
    }
    [self _layoutClipCornersIfNeeded];
  });
}

- (void)_setClipCornerLayersVisible:(BOOL)visible
{
  A_SPerformBlockOnMainThread(^{
    A_SDisplayNodeAssertMainThread();
    if (visible) {
      for (int idx = 0; idx < 4; idx++) {
        if (_clipCornerLayers[idx] == nil) {
          _clipCornerLayers[idx] = [[CALayer alloc] init];
          _clipCornerLayers[idx].zPosition = 99999;
          _clipCornerLayers[idx].delegate = self;
        }
      }
      [self _updateClipCornerLayerContentsWithRadius:_cornerRadius backgroundColor:self.backgroundColor];
    } else {
      for (int idx = 0; idx < 4; idx++) {
        [_clipCornerLayers[idx] removeFromSuperlayer];
        _clipCornerLayers[idx] = nil;
      }
    }
  });
}

- (void)updateCornerRoundingWithType:(A_SCornerRoundingType)newRoundingType cornerRadius:(CGFloat)newCornerRadius
{
  __instanceLock__.lock();
    CGFloat oldCornerRadius = _cornerRadius;
    A_SCornerRoundingType oldRoundingType = _cornerRoundingType;

    _cornerRadius = newCornerRadius;
    _cornerRoundingType = newRoundingType;
  __instanceLock__.unlock();
 
  A_SPerformBlockOnMainThread(^{
    A_SDisplayNodeAssertMainThread();
    
    if (oldRoundingType != newRoundingType || oldCornerRadius != newCornerRadius) {
      if (oldRoundingType == A_SCornerRoundingTypeDefaultSlowCALayer) {
        if (newRoundingType == A_SCornerRoundingTypePrecomposited) {
          self.layerCornerRadius = 0.0;
          if (oldCornerRadius > 0.0) {
            [self displayImmediately];
          } else {
            [self setNeedsDisplay]; // Async display is OK if we aren't replacing an existing .cornerRadius.
          }
        }
        else if (newRoundingType == A_SCornerRoundingTypeClipping) {
          self.layerCornerRadius = 0.0;
          [self _setClipCornerLayersVisible:YES];
        } else if (newRoundingType == A_SCornerRoundingTypeDefaultSlowCALayer) {
          self.layerCornerRadius = newCornerRadius;
        }
      }
      else if (oldRoundingType == A_SCornerRoundingTypePrecomposited) {
        if (newRoundingType == A_SCornerRoundingTypeDefaultSlowCALayer) {
          self.layerCornerRadius = newCornerRadius;
          [self setNeedsDisplay];
        }
        else if (newRoundingType == A_SCornerRoundingTypePrecomposited) {
          // Corners are already precomposited, but the radius has changed.
          // Default to async re-display.  The user may force a synchronous display if desired.
          [self setNeedsDisplay];
        }
        else if (newRoundingType == A_SCornerRoundingTypeClipping) {
          [self _setClipCornerLayersVisible:YES];
          [self setNeedsDisplay];
        }
      }
      else if (oldRoundingType == A_SCornerRoundingTypeClipping) {
        if (newRoundingType == A_SCornerRoundingTypeDefaultSlowCALayer) {
          self.layerCornerRadius = newCornerRadius;
          [self _setClipCornerLayersVisible:NO];
        }
        else if (newRoundingType == A_SCornerRoundingTypePrecomposited) {
          [self _setClipCornerLayersVisible:NO];
          [self displayImmediately];
        }
        else if (newRoundingType == A_SCornerRoundingTypeClipping) {
          // Clip corners already exist, but the radius has changed.
          [self _updateClipCornerLayerContentsWithRadius:newCornerRadius backgroundColor:self.backgroundColor];
        }
      }
    }
  });
}

- (void)recursivelySetDisplaySuspended:(BOOL)flag
{
  _recursivelySetDisplaySuspended(self, nil, flag);
}

// TODO: Replace this with A_SDisplayNodePerformBlockOnEveryNode or a variant with a condition / test block.
static void _recursivelySetDisplaySuspended(A_SDisplayNode *node, CALayer *layer, BOOL flag)
{
  // If there is no layer, but node whose its view is loaded, then we can traverse down its layer hierarchy.  Otherwise we must stick to the node hierarchy to avoid loading views prematurely.  Note that for nodes that haven't loaded their views, they can't possibly have subviews/sublayers, so we don't need to traverse the layer hierarchy for them.
  if (!layer && node && node.nodeLoaded) {
    layer = node.layer;
  }

  // If we don't know the node, but the layer is an async layer, get the node from the layer.
  if (!node && layer && [layer isKindOfClass:[_A_SDisplayLayer class]]) {
    node = layer.asyncdisplaykit_node;
  }

  // Set the flag on the node.  If this is a pure layer (no node) then this has no effect (plain layers don't support preventing/cancelling display).
  node.displaySuspended = flag;

  if (layer && !node.rasterizesSubtree) {
    // If there is a layer, recurse down the layer hierarchy to set the flag on descendants.  This will cover both layer-based and node-based children.
    for (CALayer *sublayer in layer.sublayers) {
      _recursivelySetDisplaySuspended(nil, sublayer, flag);
    }
  } else {
    // If there is no layer (view not loaded yet) or this node rasterizes descendants (there won't be a layer tree to traverse), recurse down the subnode hierarchy to set the flag on descendants.  This covers only node-based children, but for a node whose view is not loaded it can't possibly have nodeless children.
    for (A_SDisplayNode *subnode in node.subnodes) {
      _recursivelySetDisplaySuspended(subnode, nil, flag);
    }
  }
}

- (BOOL)displaySuspended
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.displaySuspended;
}

- (void)setDisplaySuspended:(BOOL)flag
{
  A_SDisplayNodeAssertThreadAffinity(self);
  __instanceLock__.lock();

  // Can't do this for synchronous nodes (using layers that are not _A_SDisplayLayer and so we can't control display prevention/cancel)
  if (checkFlag(Synchronous) || _flags.displaySuspended == flag) {
    __instanceLock__.unlock();
    return;
  }

  _flags.displaySuspended = flag;

  self._locked_asyncLayer.displaySuspended = flag;
  
  A_SDisplayNode *supernode = _supernode;
  __instanceLock__.unlock();

  if ([self _implementsDisplay]) {
    // Display start and finish methods needs to happen on the main thread
    A_SPerformBlockOnMainThread(^{
      if (flag) {
        [supernode subnodeDisplayDidFinish:self];
      } else {
        [supernode subnodeDisplayWillStart:self];
      }
    });
  }
}

#pragma mark <_A_SDisplayLayerDelegate>

- (void)willDisplayAsyncLayer:(_A_SDisplayLayer *)layer asynchronously:(BOOL)asynchronously
{
  // Subclass hook.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [self displayWillStart];
#pragma clang diagnostic pop

  [self displayWillStartAsynchronously:asynchronously];
}

- (void)didDisplayAsyncLayer:(_A_SDisplayLayer *)layer
{
  // Subclass hook.
  [self displayDidFinish];
}

- (void)displayWillStart {}
- (void)displayWillStartAsynchronously:(BOOL)asynchronously
{
  A_SDisplayNodeAssertMainThread();

  A_SDisplayNodeLogEvent(self, @"displayWillStart");
  // in case current node takes longer to display than it's subnodes, treat it as a dependent node
  [self _pendingNodeWillDisplay:self];
  
  __instanceLock__.lock();
  A_SDisplayNode *supernode = _supernode;
  __instanceLock__.unlock();
  
  [supernode subnodeDisplayWillStart:self];
}

- (void)displayDidFinish
{
  A_SDisplayNodeAssertMainThread();
  
  A_SDisplayNodeLogEvent(self, @"displayDidFinish");
  [self _pendingNodeDidDisplay:self];

  __instanceLock__.lock();
  A_SDisplayNode *supernode = _supernode;
  __instanceLock__.unlock();
  
  [supernode subnodeDisplayDidFinish:self];
}

- (void)subnodeDisplayWillStart:(A_SDisplayNode *)subnode
{
  // Subclass hook
  [self _pendingNodeWillDisplay:subnode];
}

- (void)subnodeDisplayDidFinish:(A_SDisplayNode *)subnode
{
  // Subclass hook
  [self _pendingNodeDidDisplay:subnode];
}

#pragma mark <CALayerDelegate>

// We are only the delegate for the layer when we are layer-backed, as UIView performs this function normally
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
  if (event == kCAOnOrderIn) {
    [self __enterHierarchy];
  } else if (event == kCAOnOrderOut) {
    [self __exitHierarchy];
  }

  A_SDisplayNodeAssert(_flags.layerBacked, @"We shouldn't get called back here unless we are layer-backed.");
  return (id)kCFNull;
}

#pragma mark - Error Handling

+ (void)setNonFatalErrorBlock:(A_SDisplayNodeNonFatalErrorBlock)nonFatalErrorBlock
{
  if (_nonFatalErrorBlock != nonFatalErrorBlock) {
    _nonFatalErrorBlock = [nonFatalErrorBlock copy];
  }
}

+ (A_SDisplayNodeNonFatalErrorBlock)nonFatalErrorBlock
{
  return _nonFatalErrorBlock;
}

#pragma mark - Converting to and from the Node's Coordinate System

- (CATransform3D)_transformToAncestor:(A_SDisplayNode *)ancestor
{
  CATransform3D transform = CATransform3DIdentity;
  A_SDisplayNode *currentNode = self;
  while (currentNode.supernode) {
    if (currentNode == ancestor) {
      return transform;
    }

    CGPoint anchorPoint = currentNode.anchorPoint;
    CGRect bounds = currentNode.bounds;
    CGPoint position = currentNode.position;
    CGPoint origin = CGPointMake(position.x - bounds.size.width * anchorPoint.x,
                                 position.y - bounds.size.height * anchorPoint.y);

    transform = CATransform3DTranslate(transform, origin.x, origin.y, 0);
    transform = CATransform3DTranslate(transform, -bounds.origin.x, -bounds.origin.y, 0);
    currentNode = currentNode.supernode;
  }
  return transform;
}

static inline CATransform3D _calculateTransformFromReferenceToTarget(A_SDisplayNode *referenceNode, A_SDisplayNode *targetNode)
{
  A_SDisplayNode *ancestor = A_SDisplayNodeFindClosestCommonAncestor(referenceNode, targetNode);

  // Transform into global (away from reference coordinate space)
  CATransform3D transformToGlobal = [referenceNode _transformToAncestor:ancestor];

  // Transform into local (via inverse transform from target to ancestor)
  CATransform3D transformToLocal = CATransform3DInvert([targetNode _transformToAncestor:ancestor]);

  return CATransform3DConcat(transformToGlobal, transformToLocal);
}

- (CGPoint)convertPoint:(CGPoint)point fromNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  /**
   * When passed node=nil, all methods in this family use the UIView-style
   * behavior – that is, convert from/to window coordinates if there's a window,
   * otherwise return the point untransformed.
   */
  if (node == nil && self.nodeLoaded) {
    CALayer *layer = self.layer;
    if (UIWindow *window = A_SFindWindowOfLayer(layer)) {
      return [layer convertPoint:point fromLayer:window.layer];
    } else {
      return point;
    }
  }
  
  // Get root node of the accessible node hierarchy, if node not specified
  node = node ? : A_SDisplayNodeUltimateParentOfNode(self);

  // Calculate transform to map points between coordinate spaces
  CATransform3D nodeTransform = _calculateTransformFromReferenceToTarget(node, self);
  CGAffineTransform flattenedTransform = CATransform3DGetAffineTransform(nodeTransform);
  A_SDisplayNodeAssertTrue(CATransform3DIsAffine(nodeTransform));

  // Apply to point
  return CGPointApplyAffineTransform(point, flattenedTransform);
}

- (CGPoint)convertPoint:(CGPoint)point toNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  if (node == nil && self.nodeLoaded) {
    CALayer *layer = self.layer;
    if (UIWindow *window = A_SFindWindowOfLayer(layer)) {
      return [layer convertPoint:point toLayer:window.layer];
    } else {
      return point;
    }
  }
  
  // Get root node of the accessible node hierarchy, if node not specified
  node = node ? : A_SDisplayNodeUltimateParentOfNode(self);

  // Calculate transform to map points between coordinate spaces
  CATransform3D nodeTransform = _calculateTransformFromReferenceToTarget(self, node);
  CGAffineTransform flattenedTransform = CATransform3DGetAffineTransform(nodeTransform);
  A_SDisplayNodeAssertTrue(CATransform3DIsAffine(nodeTransform));

  // Apply to point
  return CGPointApplyAffineTransform(point, flattenedTransform);
}

- (CGRect)convertRect:(CGRect)rect fromNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  if (node == nil && self.nodeLoaded) {
    CALayer *layer = self.layer;
    if (UIWindow *window = A_SFindWindowOfLayer(layer)) {
      return [layer convertRect:rect fromLayer:window.layer];
    } else {
      return rect;
    }
  }
  
  // Get root node of the accessible node hierarchy, if node not specified
  node = node ? : A_SDisplayNodeUltimateParentOfNode(self);

  // Calculate transform to map points between coordinate spaces
  CATransform3D nodeTransform = _calculateTransformFromReferenceToTarget(node, self);
  CGAffineTransform flattenedTransform = CATransform3DGetAffineTransform(nodeTransform);
  A_SDisplayNodeAssertTrue(CATransform3DIsAffine(nodeTransform));

  // Apply to rect
  return CGRectApplyAffineTransform(rect, flattenedTransform);
}

- (CGRect)convertRect:(CGRect)rect toNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  if (node == nil && self.nodeLoaded) {
    CALayer *layer = self.layer;
    if (UIWindow *window = A_SFindWindowOfLayer(layer)) {
      return [layer convertRect:rect toLayer:window.layer];
    } else {
      return rect;
    }
  }
  
  // Get root node of the accessible node hierarchy, if node not specified
  node = node ? : A_SDisplayNodeUltimateParentOfNode(self);

  // Calculate transform to map points between coordinate spaces
  CATransform3D nodeTransform = _calculateTransformFromReferenceToTarget(self, node);
  CGAffineTransform flattenedTransform = CATransform3DGetAffineTransform(nodeTransform);
  A_SDisplayNodeAssertTrue(CATransform3DIsAffine(nodeTransform));

  // Apply to rect
  return CGRectApplyAffineTransform(rect, flattenedTransform);
}

#pragma mark - Managing the Node Hierarchy

A_SDISPLAYNODE_INLINE bool shouldDisableNotificationsForMovingBetweenParents(A_SDisplayNode *from, A_SDisplayNode *to) {
  if (!from || !to) return NO;
  if (from.isSynchronous) return NO;
  if (to.isSynchronous) return NO;
  if (from.isInHierarchy != to.isInHierarchy) return NO;
  return YES;
}

/// Returns incremented value of i if i is not NSNotFound
A_SDISPLAYNODE_INLINE NSInteger incrementIfFound(NSInteger i) {
  return i == NSNotFound ? NSNotFound : i + 1;
}

/// Returns if a node is a member of a rasterized tree
A_SDISPLAYNODE_INLINE BOOL canUseViewAPI(A_SDisplayNode *node, A_SDisplayNode *subnode) {
  return (subnode.isLayerBacked == NO && node.isLayerBacked == NO);
}

/// Returns if node is a member of a rasterized tree
A_SDISPLAYNODE_INLINE BOOL subtreeIsRasterized(A_SDisplayNode *node) {
  return (node.rasterizesSubtree || (node.hierarchyState & A_SHierarchyStateRasterized));
}

// NOTE: This method must be dealloc-safe (should not retain self).
- (A_SDisplayNode *)supernode
{
#if CHECK_LOCKING_SAFETY
  if (__instanceLock__.ownedByCurrentThread()) {
    NSLog(@"WARNING: Accessing supernode while holding recursive instance lock of this node is worrisome. It's likely that you will soon try to acquire the supernode's lock, and this can easily cause deadlocks.");
  }
#endif
  
  A_SDN::MutexLocker l(__instanceLock__);
  return _supernode;
}

- (void)_setSupernode:(A_SDisplayNode *)newSupernode
{
  BOOL supernodeDidChange = NO;
  A_SDisplayNode *oldSupernode = nil;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if (_supernode != newSupernode) {
      oldSupernode = _supernode;  // Access supernode properties outside of lock to avoid remote chance of deadlock,
                                  // in case supernode implementation must access one of our properties.
      _supernode = newSupernode;
      supernodeDidChange = YES;
    }
  }
  
  if (supernodeDidChange) {
    A_SDisplayNodeLogEvent(self, @"supernodeDidChange: %@, oldValue = %@", A_SObjectDescriptionMakeTiny(newSupernode), A_SObjectDescriptionMakeTiny(oldSupernode));
    // Hierarchy state
    A_SHierarchyState stateToEnterOrExit = (newSupernode ? newSupernode.hierarchyState
                                                        : oldSupernode.hierarchyState);
    
    // Rasterized state
    BOOL parentWasOrIsRasterized        = (newSupernode ? newSupernode.rasterizesSubtree
                                                        : oldSupernode.rasterizesSubtree);
    if (parentWasOrIsRasterized) {
      stateToEnterOrExit |= A_SHierarchyStateRasterized;
    }
    if (newSupernode) {
      [self enterHierarchyState:stateToEnterOrExit];
      
      // If a node was added to a supernode, the supernode could be in a layout pending state. All of the hierarchy state
      // properties related to the transition need to be copied over as well as propagated down the subtree.
      // This is especially important as with automatic subnode management, adding subnodes can happen while a transition
      // is in fly
      if (A_SHierarchyStateIncludesLayoutPending(stateToEnterOrExit)) {
        int32_t pendingTransitionId = newSupernode->_pendingTransitionID;
        if (pendingTransitionId != A_SLayoutElementContextInvalidTransitionID) {
          {
            _pendingTransitionID = pendingTransitionId;
            
            // Propagate down the new pending transition id
            A_SDisplayNodePerformBlockOnEverySubnode(self, NO, ^(A_SDisplayNode * _Nonnull node) {
              node->_pendingTransitionID = pendingTransitionId;
            });
          }
        }
      }
      
      // Now that we have a supernode, propagate its traits to self.
      A_STraitCollectionPropagateDown(self, newSupernode.primitiveTraitCollection);
      
    } else {
      // If a node will be removed from the supernode it should go out from the layout pending state to remove all
      // layout pending state related properties on the node
      stateToEnterOrExit |= A_SHierarchyStateLayoutPending;
      
      [self exitHierarchyState:stateToEnterOrExit];

      // We only need to explicitly exit hierarchy here if we were rasterized.
      // Otherwise we will exit the hierarchy when our view/layer does so
      // which has some nice carry-over machinery to handle cases where we are removed from a hierarchy
      // and then added into it again shortly after.
      __instanceLock__.lock();
      BOOL isInHierarchy = _flags.isInHierarchy;
      __instanceLock__.unlock();
      
      if (parentWasOrIsRasterized && isInHierarchy) {
        [self __exitHierarchy];
      }
    }
  }
}

- (NSArray *)subnodes
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (_cachedSubnodes == nil) {
    _cachedSubnodes = [_subnodes copy];
  } else {
    A_SDisplayNodeAssert(A_SObjectIsEqual(_cachedSubnodes, _subnodes), @"Expected _subnodes and _cachedSubnodes to have the same contents.");
  }
  return _cachedSubnodes ?: @[];
}

/*
 * Central private helper method that should eventually be called if submethods add, insert or replace subnodes
 * This method is called with thread affinity.
 *
 * @param subnode       The subnode to insert
 * @param subnodeIndex  The index in _subnodes to insert it
 * @param viewSublayerIndex The index in layer.sublayers (not view.subviews) at which to insert the view (use if we can use the view API) otherwise pass NSNotFound
 * @param sublayerIndex The index in layer.sublayers at which to insert the layer (use if either parent or subnode is layer-backed) otherwise pass NSNotFound
 * @param oldSubnode Remove this subnode before inserting; ok to be nil if no removal is desired
 */
- (void)_insertSubnode:(A_SDisplayNode *)subnode atSubnodeIndex:(NSInteger)subnodeIndex sublayerIndex:(NSInteger)sublayerIndex andRemoveSubnode:(A_SDisplayNode *)oldSubnode
{
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  as_log_verbose(A_SNodeLog(), "Insert subnode %@ at index %zd of %@ and remove subnode %@", subnode, subnodeIndex, self, oldSubnode);
  
  if (subnode == nil || subnode == self) {
    A_SDisplayNodeFailAssert(@"Cannot insert a nil subnode or self as subnode");
    return;
  }
  
  if (subnodeIndex == NSNotFound) {
    A_SDisplayNodeFailAssert(@"Try to insert node on an index that was not found");
    return;
  }
  
  if (self.layerBacked && !subnode.layerBacked) {
    A_SDisplayNodeFailAssert(@"Cannot add a view-backed node as a subnode of a layer-backed node. Supernode: %@, subnode: %@", self, subnode);
    return;
  }

  BOOL isRasterized = subtreeIsRasterized(self);
  if (isRasterized && subnode.nodeLoaded) {
    A_SDisplayNodeFailAssert(@"Cannot add loaded node %@ to rasterized subtree of node %@", A_SObjectDescriptionMakeTiny(subnode), A_SObjectDescriptionMakeTiny(self));
    return;
  }

  __instanceLock__.lock();
    NSUInteger subnodesCount = _subnodes.count;
  __instanceLock__.unlock();
  if (subnodeIndex > subnodesCount || subnodeIndex < 0) {
    A_SDisplayNodeFailAssert(@"Cannot insert a subnode at index %zd. Count is %zd", subnodeIndex, subnodesCount);
    return;
  }
  
  // Disable appearance methods during move between supernodes, but make sure we restore their state after we do our thing
  A_SDisplayNode *oldParent = subnode.supernode;
  BOOL disableNotifications = shouldDisableNotificationsForMovingBetweenParents(oldParent, self);
  if (disableNotifications) {
    [subnode __incrementVisibilityNotificationsDisabled];
  }
  
  [subnode _removeFromSupernode];
  [oldSubnode _removeFromSupernode];
  
  __instanceLock__.lock();
    if (_subnodes == nil) {
      _subnodes = [[NSMutableArray alloc] init];
    }
    [_subnodes insertObject:subnode atIndex:subnodeIndex];
    _cachedSubnodes = nil;
  __instanceLock__.unlock();
  
  // This call will apply our .hierarchyState to the new subnode.
  // If we are a managed hierarchy, as in A_SCellNode trees, it will also apply our .interfaceState.
  [subnode _setSupernode:self];

  // If this subnode will be rasterized, enter hierarchy if needed
  // TODO: Move this into _setSupernode: ?
  if (isRasterized) {
    if (self.inHierarchy) {
      [subnode __enterHierarchy];
    }
  } else if (self.nodeLoaded) {
    // If not rasterizing, and node is loaded insert the subview/sublayer now.
    [self _insertSubnodeSubviewOrSublayer:subnode atIndex:sublayerIndex];
  } // Otherwise we will insert subview/sublayer when we get loaded

  A_SDisplayNodeAssert(disableNotifications == shouldDisableNotificationsForMovingBetweenParents(oldParent, self), @"Invariant violated");
  if (disableNotifications) {
    [subnode __decrementVisibilityNotificationsDisabled];
  }
}

/*
 * Inserts the view or layer of the given node at the given index
 *
 * @param subnode       The subnode to insert
 * @param idx           The index in _view.subviews or _layer.sublayers at which to insert the subnode.view or
 *                      subnode.layer of the subnode
 */
- (void)_insertSubnodeSubviewOrSublayer:(A_SDisplayNode *)subnode atIndex:(NSInteger)idx
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(self.nodeLoaded, @"_insertSubnodeSubviewOrSublayer:atIndex: should never be called before our own view is created");

  A_SDisplayNodeAssert(idx != NSNotFound, @"Try to insert node on an index that was not found");
  if (idx == NSNotFound) {
    return;
  }
  
  // Because the view and layer can only be created and destroyed on Main, that is also the only thread
  // where the view and layer can change. We can avoid locking.

  // If we can use view API, do. Due to an apple bug, -insertSubview:atIndex: actually wants a LAYER index,
  // which we pass in.
  if (canUseViewAPI(self, subnode)) {
    [_view insertSubview:subnode.view atIndex:idx];
  } else {
    [_layer insertSublayer:subnode.layer atIndex:(unsigned int)idx];
  }
}

- (void)addSubnode:(A_SDisplayNode *)subnode
{
  A_SDisplayNodeLogEvent(self, @"addSubnode: %@ with automaticallyManagesSubnodes: %@",
                        subnode, self.automaticallyManagesSubnodes ? @"YES" : @"NO");
  [self _addSubnode:subnode];
}

- (void)_addSubnode:(A_SDisplayNode *)subnode
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  A_SDisplayNodeAssert(subnode, @"Cannot insert a nil subnode");
    
  // Don't add if it's already a subnode
  A_SDisplayNode *oldParent = subnode.supernode;
  if (!subnode || subnode == self || oldParent == self) {
    return;
  }

  NSUInteger subnodesIndex;
  NSUInteger sublayersIndex;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    subnodesIndex = _subnodes.count;
    sublayersIndex = _layer.sublayers.count;
  }
  
  [self _insertSubnode:subnode atSubnodeIndex:subnodesIndex sublayerIndex:sublayersIndex andRemoveSubnode:nil];
}

- (void)_addSubnodeViewsAndLayers
{
  A_SDisplayNodeAssertMainThread();
  
  TIME_SCOPED(_debugTimeToAddSubnodeViews);
  
  for (A_SDisplayNode *node in self.subnodes) {
    [self _addSubnodeSubviewOrSublayer:node];
  }
}

- (void)_addSubnodeSubviewOrSublayer:(A_SDisplayNode *)subnode
{
  A_SDisplayNodeAssertMainThread();
  
  // Due to a bug in Apple's framework we have to use the layer index to insert a subview
  // so just use the count of the sublayers to add the subnode
  NSInteger idx = _layer.sublayers.count; // No locking is needed as it's main thread only
  [self _insertSubnodeSubviewOrSublayer:subnode atIndex:idx];
}

- (void)replaceSubnode:(A_SDisplayNode *)oldSubnode withSubnode:(A_SDisplayNode *)replacementSubnode
{
  A_SDisplayNodeLogEvent(self, @"replaceSubnode: %@ withSubnode: %@ with automaticallyManagesSubnodes: %@",
                        oldSubnode, replacementSubnode, self.automaticallyManagesSubnodes ? @"YES" : @"NO");
  [self _replaceSubnode:oldSubnode withSubnode:replacementSubnode];
}

- (void)_replaceSubnode:(A_SDisplayNode *)oldSubnode withSubnode:(A_SDisplayNode *)replacementSubnode
{
  A_SDisplayNodeAssertThreadAffinity(self);

  if (replacementSubnode == nil) {
    A_SDisplayNodeFailAssert(@"Invalid subnode to replace");
    return;
  }
  
  if (oldSubnode.supernode != self) {
    A_SDisplayNodeFailAssert(@"Old Subnode to replace must be a subnode");
    return;
  }

  A_SDisplayNodeAssert(!(self.nodeLoaded && !oldSubnode.nodeLoaded), @"We have view loaded, but child node does not.");

  NSInteger subnodeIndex;
  NSInteger sublayerIndex = NSNotFound;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    A_SDisplayNodeAssert(_subnodes, @"You should have subnodes if you have a subnode");
    
    subnodeIndex = [_subnodes indexOfObjectIdenticalTo:oldSubnode];
    
    // Don't bother figuring out the sublayerIndex if in a rasterized subtree, because there are no layers in the
    // hierarchy and none of this could possibly work.
    if (subtreeIsRasterized(self) == NO) {
      if (_layer) {
        sublayerIndex = [_layer.sublayers indexOfObjectIdenticalTo:oldSubnode.layer];
        A_SDisplayNodeAssert(sublayerIndex != NSNotFound, @"Somehow oldSubnode's supernode is self, yet we could not find it in our layers to replace");
        if (sublayerIndex == NSNotFound) {
          return;
        }
      }
    }
  }

  [self _insertSubnode:replacementSubnode atSubnodeIndex:subnodeIndex sublayerIndex:sublayerIndex andRemoveSubnode:oldSubnode];
}

- (void)insertSubnode:(A_SDisplayNode *)subnode belowSubnode:(A_SDisplayNode *)below
{
  A_SDisplayNodeLogEvent(self, @"insertSubnode: %@ belowSubnode: %@ with automaticallyManagesSubnodes: %@",
                        subnode, below, self.automaticallyManagesSubnodes ? @"YES" : @"NO");
  [self _insertSubnode:subnode belowSubnode:below];
}

- (void)_insertSubnode:(A_SDisplayNode *)subnode belowSubnode:(A_SDisplayNode *)below
{
  A_SDisplayNodeAssertThreadAffinity(self);

  if (subnode == nil) {
    A_SDisplayNodeFailAssert(@"Cannot insert a nil subnode");
    return;
  }

  if (below.supernode != self) {
    A_SDisplayNodeFailAssert(@"Node to insert below must be a subnode");
    return;
  }

  NSInteger belowSubnodeIndex;
  NSInteger belowSublayerIndex = NSNotFound;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    A_SDisplayNodeAssert(_subnodes, @"You should have subnodes if you have a subnode");
    
    belowSubnodeIndex = [_subnodes indexOfObjectIdenticalTo:below];
    
    // Don't bother figuring out the sublayerIndex if in a rasterized subtree, because there are no layers in the
    // hierarchy and none of this could possibly work.
    if (subtreeIsRasterized(self) == NO) {
      if (_layer) {
        belowSublayerIndex = [_layer.sublayers indexOfObjectIdenticalTo:below.layer];
        A_SDisplayNodeAssert(belowSublayerIndex != NSNotFound, @"Somehow below's supernode is self, yet we could not find it in our layers to reference");
        if (belowSublayerIndex == NSNotFound)
          return;
      }
      
      A_SDisplayNodeAssert(belowSubnodeIndex != NSNotFound, @"Couldn't find above in subnodes");
      
      // If the subnode is already in the subnodes array / sublayers and it's before the below node, removing it to
      // insert it will mess up our calculation
      if (subnode.supernode == self) {
        NSInteger currentIndexInSubnodes = [_subnodes indexOfObjectIdenticalTo:subnode];
        if (currentIndexInSubnodes < belowSubnodeIndex) {
          belowSubnodeIndex--;
        }
        if (_layer) {
          NSInteger currentIndexInSublayers = [_layer.sublayers indexOfObjectIdenticalTo:subnode.layer];
          if (currentIndexInSublayers < belowSublayerIndex) {
            belowSublayerIndex--;
          }
        }
      }
    }
  }

  A_SDisplayNodeAssert(belowSubnodeIndex != NSNotFound, @"Couldn't find below in subnodes");

  [self _insertSubnode:subnode atSubnodeIndex:belowSubnodeIndex sublayerIndex:belowSublayerIndex andRemoveSubnode:nil];
}

- (void)insertSubnode:(A_SDisplayNode *)subnode aboveSubnode:(A_SDisplayNode *)above
{
  A_SDisplayNodeLogEvent(self, @"insertSubnode: %@ abodeSubnode: %@ with automaticallyManagesSubnodes: %@",
                        subnode, above, self.automaticallyManagesSubnodes ? @"YES" : @"NO");
  [self _insertSubnode:subnode aboveSubnode:above];
}

- (void)_insertSubnode:(A_SDisplayNode *)subnode aboveSubnode:(A_SDisplayNode *)above
{
  A_SDisplayNodeAssertThreadAffinity(self);

  if (subnode == nil) {
    A_SDisplayNodeFailAssert(@"Cannot insert a nil subnode");
    return;
  }

  if (above.supernode != self) {
    A_SDisplayNodeFailAssert(@"Node to insert above must be a subnode");
    return;
  }

  NSInteger aboveSubnodeIndex;
  NSInteger aboveSublayerIndex = NSNotFound;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    A_SDisplayNodeAssert(_subnodes, @"You should have subnodes if you have a subnode");
    
    aboveSubnodeIndex = [_subnodes indexOfObjectIdenticalTo:above];
    
    // Don't bother figuring out the sublayerIndex if in a rasterized subtree, because there are no layers in the
    // hierarchy and none of this could possibly work.
    if (subtreeIsRasterized(self) == NO) {
      if (_layer) {
        aboveSublayerIndex = [_layer.sublayers indexOfObjectIdenticalTo:above.layer];
        A_SDisplayNodeAssert(aboveSublayerIndex != NSNotFound, @"Somehow above's supernode is self, yet we could not find it in our layers to replace");
        if (aboveSublayerIndex == NSNotFound)
          return;
      }
      
      A_SDisplayNodeAssert(aboveSubnodeIndex != NSNotFound, @"Couldn't find above in subnodes");
      
      // If the subnode is already in the subnodes array / sublayers and it's before the below node, removing it to
      // insert it will mess up our calculation
      if (subnode.supernode == self) {
        NSInteger currentIndexInSubnodes = [_subnodes indexOfObjectIdenticalTo:subnode];
        if (currentIndexInSubnodes <= aboveSubnodeIndex) {
          aboveSubnodeIndex--;
        }
        if (_layer) {
          NSInteger currentIndexInSublayers = [_layer.sublayers indexOfObjectIdenticalTo:subnode.layer];
          if (currentIndexInSublayers <= aboveSublayerIndex) {
            aboveSublayerIndex--;
          }
        }
      }
    }
  }

  [self _insertSubnode:subnode atSubnodeIndex:incrementIfFound(aboveSubnodeIndex) sublayerIndex:incrementIfFound(aboveSublayerIndex) andRemoveSubnode:nil];
}

- (void)insertSubnode:(A_SDisplayNode *)subnode atIndex:(NSInteger)idx
{
  A_SDisplayNodeLogEvent(self, @"insertSubnode: %@ atIndex: %td with automaticallyManagesSubnodes: %@",
                        subnode, idx, self.automaticallyManagesSubnodes ? @"YES" : @"NO");
  [self _insertSubnode:subnode atIndex:idx];
}

- (void)_insertSubnode:(A_SDisplayNode *)subnode atIndex:(NSInteger)idx
{
  A_SDisplayNodeAssertThreadAffinity(self);
  
  if (subnode == nil) {
    A_SDisplayNodeFailAssert(@"Cannot insert a nil subnode");
    return;
  }

  NSInteger sublayerIndex = NSNotFound;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    
    if (idx > _subnodes.count || idx < 0) {
      A_SDisplayNodeFailAssert(@"Cannot insert a subnode at index %zd. Count is %zd", idx, _subnodes.count);
      return;
    }
    
    // Don't bother figuring out the sublayerIndex if in a rasterized subtree, because there are no layers in the
    // hierarchy and none of this could possibly work.
    if (subtreeIsRasterized(self) == NO) {
      // Account for potentially having other subviews
      if (_layer && idx == 0) {
        sublayerIndex = 0;
      } else if (_layer) {
        A_SDisplayNode *positionInRelationTo = (_subnodes.count > 0 && idx > 0) ? _subnodes[idx - 1] : nil;
        if (positionInRelationTo) {
          sublayerIndex = incrementIfFound([_layer.sublayers indexOfObjectIdenticalTo:positionInRelationTo.layer]);
        }
      }
    }
  }

  [self _insertSubnode:subnode atSubnodeIndex:idx sublayerIndex:sublayerIndex andRemoveSubnode:nil];
}

- (void)_removeSubnode:(A_SDisplayNode *)subnode
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  // Don't call self.supernode here because that will retain/autorelease the supernode.  This method -_removeSupernode: is often called while tearing down a node hierarchy, and the supernode in question might be in the middle of its -dealloc.  The supernode is never messaged, only compared by value, so this is safe.
  // The particular issue that triggers this edge case is when a node calls -removeFromSupernode on a subnode from within its own -dealloc method.
  if (!subnode || subnode.supernode != self) {
    return;
  }

  __instanceLock__.lock();
    [_subnodes removeObjectIdenticalTo:subnode];
    _cachedSubnodes = nil;
  __instanceLock__.unlock();

  [subnode _setSupernode:nil];
}

- (void)removeFromSupernode
{
  A_SDisplayNodeLogEvent(self, @"removeFromSupernode with automaticallyManagesSubnodes: %@",
                        self.automaticallyManagesSubnodes ? @"YES" : @"NO");
  [self _removeFromSupernode];
}

- (void)_removeFromSupernode
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  __instanceLock__.lock();
    __weak A_SDisplayNode *supernode = _supernode;
    __weak UIView *view = _view;
    __weak CALayer *layer = _layer;
  __instanceLock__.unlock();

  [self _removeFromSupernode:supernode view:view layer:layer];
}

- (void)_removeFromSupernodeIfEqualTo:(A_SDisplayNode *)supernode
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  __instanceLock__.lock();

    // Only remove if supernode is still the expected supernode
    if (!A_SObjectIsEqual(_supernode, supernode)) {
      __instanceLock__.unlock();
      return;
    }
  
    __weak UIView *view = _view;
    __weak CALayer *layer = _layer;
  __instanceLock__.unlock();
  
  [self _removeFromSupernode:supernode view:view layer:layer];
}

- (void)_removeFromSupernode:(A_SDisplayNode *)supernode view:(UIView *)view layer:(CALayer *)layer
{
  // Note: we continue even if supernode is nil to ensure view/layer are removed from hierarchy.

  if (supernode != nil) {
    as_log_verbose(A_SNodeLog(), "Remove %@ from supernode %@", self, supernode);
  }

  // Clear supernode's reference to us before removing the view from the hierarchy, as _A_SDisplayView
  // will trigger us to clear our _supernode pointer in willMoveToSuperview:nil.
  // This may result in removing the last strong reference, triggering deallocation after this method.
  [supernode _removeSubnode:self];
  
  if (view != nil) {
    [view removeFromSuperview];
  } else if (layer != nil) {
    [layer removeFromSuperlayer];
  }
}

#pragma mark - Visibility API

- (BOOL)__visibilityNotificationsDisabled
{
  // Currently, this method is only used by the testing infrastructure to verify this internal feature.
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.visibilityNotificationsDisabled > 0;
}

- (BOOL)__selfOrParentHasVisibilityNotificationsDisabled
{
  A_SDN::MutexLocker l(__instanceLock__);
  return (_hierarchyState & A_SHierarchyStateTransitioningSupernodes);
}

- (void)__incrementVisibilityNotificationsDisabled
{
  __instanceLock__.lock();
  const size_t maxVisibilityIncrement = (1ULL<<VISIBILITY_NOTIFICATIONS_DISABLED_BITS) - 1ULL;
  A_SDisplayNodeAssert(_flags.visibilityNotificationsDisabled < maxVisibilityIncrement, @"Oops, too many increments of the visibility notifications API");
  if (_flags.visibilityNotificationsDisabled < maxVisibilityIncrement) {
    _flags.visibilityNotificationsDisabled++;
  }
  BOOL visibilityNotificationsDisabled = (_flags.visibilityNotificationsDisabled == 1);
  __instanceLock__.unlock();

  if (visibilityNotificationsDisabled) {
    // Must have just transitioned from 0 to 1.  Notify all subnodes that we are in a disabled state.
    [self enterHierarchyState:A_SHierarchyStateTransitioningSupernodes];
  }
}

- (void)__decrementVisibilityNotificationsDisabled
{
  __instanceLock__.lock();
  A_SDisplayNodeAssert(_flags.visibilityNotificationsDisabled > 0, @"Can't decrement past 0");
  if (_flags.visibilityNotificationsDisabled > 0) {
    _flags.visibilityNotificationsDisabled--;
  }
  BOOL visibilityNotificationsDisabled = (_flags.visibilityNotificationsDisabled == 0);
  __instanceLock__.unlock();

  if (visibilityNotificationsDisabled) {
    // Must have just transitioned from 1 to 0.  Notify all subnodes that we are no longer in a disabled state.
    // FIXME: This system should be revisited when refactoring and consolidating the implementation of the
    // addSubnode: and insertSubnode:... methods.  As implemented, though logically irrelevant for expected use cases,
    // multiple nodes in the subtree below may have a non-zero visibilityNotification count and still have
    // the A_SHierarchyState bit cleared (the only value checked when reading this state).
    [self exitHierarchyState:A_SHierarchyStateTransitioningSupernodes];
  }
}

#pragma mark - Placeholder

- (void)_locked_layoutPlaceholderIfNecessary
{
  if ([self _locked_shouldHavePlaceholderLayer]) {
    [self _locked_setupPlaceholderLayerIfNeeded];
  }
  // Update the placeholderLayer size in case the node size has changed since the placeholder was added.
  _placeholderLayer.frame = self.threadSafeBounds;
}

- (BOOL)_locked_shouldHavePlaceholderLayer
{
  return (_placeholderEnabled && [self _implementsDisplay]);
}

- (void)_locked_setupPlaceholderLayerIfNeeded
{
  A_SDisplayNodeAssertMainThread();

  if (!_placeholderLayer) {
    _placeholderLayer = [CALayer layer];
    // do not set to CGFLOAT_MAX in the case that something needs to be overtop the placeholder
    _placeholderLayer.zPosition = 9999.0;
  }

  if (_placeholderLayer.contents == nil) {
    if (!_placeholderImage) {
      _placeholderImage = [self placeholderImage];
    }
    if (_placeholderImage) {
      BOOL stretchable = !UIEdgeInsetsEqualToEdgeInsets(_placeholderImage.capInsets, UIEdgeInsetsZero);
      if (stretchable) {
        A_SDisplayNodeSetResizableContents(_placeholderLayer, _placeholderImage);
      } else {
        _placeholderLayer.contentsScale = self.contentsScale;
        _placeholderLayer.contents = (id)_placeholderImage.CGImage;
      }
    }
  }
}

- (UIImage *)placeholderImage
{
  // Subclass hook
  return nil;
}

- (BOOL)placeholderShouldPersist
{
  // Subclass hook
  return NO;
}

#pragma mark - Hierarchy State

- (BOOL)isInHierarchy
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _flags.isInHierarchy;
}

- (void)__enterHierarchy
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(!_flags.isEnteringHierarchy, @"Should not cause recursive __enterHierarchy");
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  A_SDisplayNodeLogEvent(self, @"enterHierarchy");
  
  // Profiling has shown that locking this method is beneficial, so each of the property accesses don't have to lock and unlock.
  __instanceLock__.lock();
  
  if (!_flags.isInHierarchy && !_flags.visibilityNotificationsDisabled && ![self __selfOrParentHasVisibilityNotificationsDisabled]) {
    _flags.isEnteringHierarchy = YES;
    _flags.isInHierarchy = YES;

    // Don't call -willEnterHierarchy while holding __instanceLock__.
    // This method and subsequent ones (i.e -interfaceState and didEnter(.*)State)
    // don't expect that they are called while the lock is being held.
    // More importantly, didEnter(.*)State methods are meant to be overriden by clients.
    // And so they can potentially walk up the node tree and cause deadlocks, or do expensive tasks and cause the lock to be held for too long.
    __instanceLock__.unlock();
      [self willEnterHierarchy];
      for (A_SDisplayNode *subnode in self.subnodes) {
        [subnode __enterHierarchy];
      }
    __instanceLock__.lock();
    
    _flags.isEnteringHierarchy = NO;

    // If we don't have contents finished drawing by the time we are on screen, immediately add the placeholder (if it is enabled and we do have something to draw).
    if (self.contents == nil) {
      CALayer *layer = self.layer;
      [layer setNeedsDisplay];
      
      if ([self _locked_shouldHavePlaceholderLayer]) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self _locked_setupPlaceholderLayerIfNeeded];
        _placeholderLayer.opacity = 1.0;
        [CATransaction commit];
        [layer addSublayer:_placeholderLayer];
      }
    }
  }
  
  __instanceLock__.unlock();
}

- (void)__exitHierarchy
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(!_flags.isExitingHierarchy, @"Should not cause recursive __exitHierarchy");
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  A_SDisplayNodeLogEvent(self, @"exitHierarchy");
  
  // Profiling has shown that locking this method is beneficial, so each of the property accesses don't have to lock and unlock.
  __instanceLock__.lock();
  
  if (_flags.isInHierarchy && !_flags.visibilityNotificationsDisabled && ![self __selfOrParentHasVisibilityNotificationsDisabled]) {
    _flags.isExitingHierarchy = YES;
    _flags.isInHierarchy = NO;

    [self._locked_asyncLayer cancelAsyncDisplay];

    // Don't call -didExitHierarchy while holding __instanceLock__.
    // This method and subsequent ones (i.e -interfaceState and didExit(.*)State)
    // don't expect that they are called while the lock is being held.
    // More importantly, didExit(.*)State methods are meant to be overriden by clients.
    // And so they can potentially walk up the node tree and cause deadlocks, or do expensive tasks and cause the lock to be held for too long.
    __instanceLock__.unlock();
      [self didExitHierarchy];
      for (A_SDisplayNode *subnode in self.subnodes) {
        [subnode __exitHierarchy];
      }
    __instanceLock__.lock();
    
    _flags.isExitingHierarchy = NO;
  }
  
  __instanceLock__.unlock();
}

- (void)enterHierarchyState:(A_SHierarchyState)hierarchyState
{
  if (hierarchyState == A_SHierarchyStateNormal) {
    return; // This method is a no-op with a 0-bitfield argument, so don't bother recursing.
  }
  
  A_SDisplayNodePerformBlockOnEveryNode(nil, self, NO, ^(A_SDisplayNode *node) {
    node.hierarchyState |= hierarchyState;
  });
}

- (void)exitHierarchyState:(A_SHierarchyState)hierarchyState
{
  if (hierarchyState == A_SHierarchyStateNormal) {
    return; // This method is a no-op with a 0-bitfield argument, so don't bother recursing.
  }
  A_SDisplayNodePerformBlockOnEveryNode(nil, self, NO, ^(A_SDisplayNode *node) {
    node.hierarchyState &= (~hierarchyState);
  });
}

- (A_SHierarchyState)hierarchyState
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _hierarchyState;
}

- (void)setHierarchyState:(A_SHierarchyState)newState
{
  A_SHierarchyState oldState = A_SHierarchyStateNormal;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if (_hierarchyState == newState) {
      return;
    }
    oldState = _hierarchyState;
    _hierarchyState = newState;
  }
  
  // Entered rasterization state.
  if (newState & A_SHierarchyStateRasterized) {
    A_SDisplayNodeAssert(checkFlag(Synchronous) == NO, @"Node created using -initWithViewBlock:/-initWithLayerBlock: cannot be added to subtree of node with subtree rasterization enabled. Node: %@", self);
  }
  
  // Entered or exited range managed state.
  if ((newState & A_SHierarchyStateRangeManaged) != (oldState & A_SHierarchyStateRangeManaged)) {
    if (newState & A_SHierarchyStateRangeManaged) {
      [self enterInterfaceState:self.supernode.interfaceState];
    } else {
      // The case of exiting a range-managed state should be fairly rare.  Adding or removing the node
      // to a view hierarchy will cause its interfaceState to be either fully set or unset (all fields),
      // but because we might be about to be added to a view hierarchy, exiting the interface state now
      // would cause inefficient churn.  The tradeoff is that we may not clear contents / fetched data
      // for nodes that are removed from a managed state and then retained but not used (bad idea anyway!)
    }
  }
  
  if ((newState & A_SHierarchyStateLayoutPending) != (oldState & A_SHierarchyStateLayoutPending)) {
    if (newState & A_SHierarchyStateLayoutPending) {
      // Entering layout pending state
    } else {
      // Leaving layout pending state, reset related properties
      A_SDN::MutexLocker l(__instanceLock__);
      _pendingTransitionID = A_SLayoutElementContextInvalidTransitionID;
      _pendingLayoutTransition = nil;
    }
  }

  A_SDisplayNodeLogEvent(self, @"setHierarchyState: oldState = %@, newState = %@", NSStringFromA_SHierarchyState(oldState), NSStringFromA_SHierarchyState(newState));
}

- (void)willEnterHierarchy
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(_flags.isEnteringHierarchy, @"You should never call -willEnterHierarchy directly. Appearance is automatically managed by A_SDisplayNode");
  A_SDisplayNodeAssert(!_flags.isExitingHierarchy, @"A_SDisplayNode inconsistency. __enterHierarchy and __exitHierarchy are mutually exclusive");
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  if (![self supportsRangeManagedInterfaceState]) {
    self.interfaceState = A_SInterfaceStateInHierarchy;
  }
}

- (void)didExitHierarchy
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(_flags.isExitingHierarchy, @"You should never call -didExitHierarchy directly. Appearance is automatically managed by A_SDisplayNode");
  A_SDisplayNodeAssert(!_flags.isEnteringHierarchy, @"A_SDisplayNode inconsistency. __enterHierarchy and __exitHierarchy are mutually exclusive");
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  if (![self supportsRangeManagedInterfaceState]) {
    self.interfaceState = A_SInterfaceStateNone;
  } else {
    // This case is important when tearing down hierarchies.  We must deliver a visibileStateDidChange:NO callback, as part our API guarantee that this method can be used for
    // things like data analytics about user content viewing.  We cannot call the method in the dealloc as any incidental retain operations in client code would fail.
    // Additionally, it may be that a Standard UIView which is containing us is moving between hierarchies, and we should not send the call if we will be re-added in the
    // same runloop.  Strategy: strong reference (might be the last!), wait one runloop, and confirm we are still outside the hierarchy (both layer-backed and view-backed).
    // TODO: This approach could be optimized by only performing the dispatch for root elements + recursively apply the interface state change. This would require a closer
    // integration with _A_SDisplayLayer to ensure that the superlayer pointer has been cleared by this stage (to check if we are root or not), or a different delegate call.
    
    if (A_SInterfaceStateIncludesVisible(self.interfaceState)) {
      dispatch_async(dispatch_get_main_queue(), ^{
        // This block intentionally retains self.
        __instanceLock__.lock();
          unsigned isInHierarchy = _flags.isInHierarchy;
          BOOL isVisible = A_SInterfaceStateIncludesVisible(_interfaceState);
          A_SInterfaceState newState = (_interfaceState & ~A_SInterfaceStateVisible);
        __instanceLock__.unlock();
        
        if (!isInHierarchy && isVisible) {
          self.interfaceState = newState;
        }
      });
    }
  }
}

#pragma mark - Interface State

/**
 * We currently only set interface state on nodes in table/collection views. For other nodes, if they are
 * in the hierarchy we enable all A_SInterfaceState types with `A_SInterfaceStateInHierarchy`, otherwise `None`.
 */
- (BOOL)supportsRangeManagedInterfaceState
{
  A_SDN::MutexLocker l(__instanceLock__);
  return A_SHierarchyStateIncludesRangeManaged(_hierarchyState);
}

- (void)enterInterfaceState:(A_SInterfaceState)interfaceState
{
  if (interfaceState == A_SInterfaceStateNone) {
    return; // This method is a no-op with a 0-bitfield argument, so don't bother recursing.
  }
  A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode *node) {
    node.interfaceState |= interfaceState;
  });
}

- (void)exitInterfaceState:(A_SInterfaceState)interfaceState
{
  if (interfaceState == A_SInterfaceStateNone) {
    return; // This method is a no-op with a 0-bitfield argument, so don't bother recursing.
  }
  A_SDisplayNodeLogEvent(self, @"%s %@", sel_getName(_cmd), NSStringFromA_SInterfaceState(interfaceState));
  A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode *node) {
    node.interfaceState &= (~interfaceState);
  });
}

- (void)recursivelySetInterfaceState:(A_SInterfaceState)newInterfaceState
{
  as_activity_create_for_scope("Recursively set interface state");

  // Instead of each node in the recursion assuming it needs to schedule itself for display,
  // setInterfaceState: skips this when handling range-managed nodes (our whole subtree has this set).
  // If our range manager intends for us to be displayed right now, and didn't before, get started!
  BOOL shouldScheduleDisplay = [self supportsRangeManagedInterfaceState] && [self shouldScheduleDisplayWithNewInterfaceState:newInterfaceState];
  A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode *node) {
    node.interfaceState = newInterfaceState;
  });
  if (shouldScheduleDisplay) {
    [A_SDisplayNode scheduleNodeForRecursiveDisplay:self];
  }
}

- (A_SInterfaceState)interfaceState
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _interfaceState;
}

- (void)setInterfaceState:(A_SInterfaceState)newState
{
  //This method is currently called on the main thread. The assert has been added here because all of the
  //did(Enter|Exit)(Display|Visible|Preload)State methods currently guarantee calling on main.
  A_SDisplayNodeAssertMainThread();
  // It should never be possible for a node to be visible but not be allowed / expected to display.
  A_SDisplayNodeAssertFalse(A_SInterfaceStateIncludesVisible(newState) && !A_SInterfaceStateIncludesDisplay(newState));
  // This method manages __instanceLock__ itself, to ensure the lock is not held while didEnter/Exit(.*)State methods are called, thus avoid potential deadlocks
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  A_SInterfaceState oldState = A_SInterfaceStateNone;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if (_interfaceState == newState) {
      return;
    }
    oldState = _interfaceState;
    _interfaceState = newState;
  }

  // TODO: Trigger asynchronous measurement if it is not already cached or being calculated.
  // if ((newState & A_SInterfaceStateMeasureLayout) != (oldState & A_SInterfaceStateMeasureLayout)) {
  // }
  
  // For the Preload and Display ranges, we don't want to call -clear* if not being managed by a range controller.
  // Otherwise we get flashing behavior from normal UIKit manipulations like navigation controller push / pop.
  // Still, the interfaceState should be updated to the current state of the node; just don't act on the transition.
  
  // Entered or exited data loading state.
  BOOL nowPreload = A_SInterfaceStateIncludesPreload(newState);
  BOOL wasPreload = A_SInterfaceStateIncludesPreload(oldState);
  
  if (nowPreload != wasPreload) {
    if (nowPreload) {
      [self didEnterPreloadState];
    } else {
      // We don't want to call -didExitPreloadState on nodes that aren't being managed by a range controller.
      // Otherwise we get flashing behavior from normal UIKit manipulations like navigation controller push / pop.
      if ([self supportsRangeManagedInterfaceState]) {
        [self didExitPreloadState];
      }
    }
  }
  
  // Entered or exited contents rendering state.
  BOOL nowDisplay = A_SInterfaceStateIncludesDisplay(newState);
  BOOL wasDisplay = A_SInterfaceStateIncludesDisplay(oldState);

  if (nowDisplay != wasDisplay) {
    if ([self supportsRangeManagedInterfaceState]) {
      if (nowDisplay) {
        // Once the working window is eliminated (A_SRangeHandlerRender), trigger display directly here.
        [self setDisplaySuspended:NO];
      } else {
        [self setDisplaySuspended:YES];
        //schedule clear contents on next runloop
        dispatch_async(dispatch_get_main_queue(), ^{
          A_SDN::MutexLocker l(__instanceLock__);
          if (A_SInterfaceStateIncludesDisplay(_interfaceState) == NO) {
            [self clearContents];
          }
        });
      }
    } else {
      // NOTE: This case isn't currently supported as setInterfaceState: isn't exposed externally, and all
      // internal use cases are range-managed.  When a node is visible, don't mess with display - CA will start it.
      if (!A_SInterfaceStateIncludesVisible(newState)) {
        // Check _implementsDisplay purely for efficiency - it's faster even than calling -asyncLayer.
        if ([self _implementsDisplay]) {
          if (nowDisplay) {
            [A_SDisplayNode scheduleNodeForRecursiveDisplay:self];
          } else {
            [[self asyncLayer] cancelAsyncDisplay];
            //schedule clear contents on next runloop
            dispatch_async(dispatch_get_main_queue(), ^{
              A_SDN::MutexLocker l(__instanceLock__);
              if (A_SInterfaceStateIncludesDisplay(_interfaceState) == NO) {
                [self clearContents];
              }
            });
          }
        }
      }
    }
    
    if (nowDisplay) {
      [self didEnterDisplayState];
    } else {
      [self didExitDisplayState];
    }
  }

  // Became visible or invisible.  When range-managed, this represents literal visibility - at least one pixel
  // is onscreen.  If not range-managed, we can't guarantee more than the node being present in an onscreen window.
  BOOL nowVisible = A_SInterfaceStateIncludesVisible(newState);
  BOOL wasVisible = A_SInterfaceStateIncludesVisible(oldState);

  if (nowVisible != wasVisible) {
    if (nowVisible) {
      [self didEnterVisibleState];
    } else {
      [self didExitVisibleState];
    }
  }

  // Log this change, unless it's just the node going from {} -> {Measure} because that change happens
  // for all cell nodes and it isn't currently meaningful.
  BOOL measureChangeOnly = ((oldState | newState) == A_SInterfaceStateMeasureLayout);
  if (!measureChangeOnly) {
    as_log_verbose(A_SNodeLog(), "%s %@ %@", sel_getName(_cmd), NSStringFromA_SInterfaceStateChange(oldState, newState), self);
  }
  
  A_SDisplayNodeLogEvent(self, @"interfaceStateDidChange: %@", NSStringFromA_SInterfaceStateChange(oldState, newState));
  [self interfaceStateDidChange:newState fromState:oldState];
}

- (void)interfaceStateDidChange:(A_SInterfaceState)newState fromState:(A_SInterfaceState)oldState
{
  // Subclass hook
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate interfaceStateDidChange:newState fromState:oldState];
}

- (BOOL)shouldScheduleDisplayWithNewInterfaceState:(A_SInterfaceState)newInterfaceState
{
  BOOL willDisplay = A_SInterfaceStateIncludesDisplay(newInterfaceState);
  BOOL nowDisplay = A_SInterfaceStateIncludesDisplay(self.interfaceState);
  return willDisplay && (willDisplay != nowDisplay);
}

- (BOOL)isVisible
{
  A_SDN::MutexLocker l(__instanceLock__);
  return A_SInterfaceStateIncludesVisible(_interfaceState);
}

- (void)didEnterVisibleState
{
  // subclass override
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate didEnterVisibleState];
#if A_S_ENABLE_TIPS
  [A_STipsController.shared nodeDidAppear:self];
#endif
}

- (void)didExitVisibleState
{
  // subclass override
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate didExitVisibleState];
}

- (BOOL)isInDisplayState
{
  A_SDN::MutexLocker l(__instanceLock__);
  return A_SInterfaceStateIncludesDisplay(_interfaceState);
}

- (void)didEnterDisplayState
{
  // subclass override
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate didEnterDisplayState];
}

- (void)didExitDisplayState
{
  // subclass override
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate didExitDisplayState];
}

- (BOOL)isInPreloadState
{
  A_SDN::MutexLocker l(__instanceLock__);
  return A_SInterfaceStateIncludesPreload(_interfaceState);
}

- (void)setNeedsPreload
{
  if (self.isInPreloadState) {
    [self recursivelyPreload];
  }
}

- (void)recursivelyPreload
{
  A_SPerformBlockOnMainThread(^{
    A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode * _Nonnull node) {
      [node didEnterPreloadState];
    });
  });
}

- (void)recursivelyClearPreloadedData
{
  A_SPerformBlockOnMainThread(^{
    A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode * _Nonnull node) {
      [node didExitPreloadState];
    });
  });
}

- (void)didEnterPreloadState
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate didEnterPreloadState];
}

- (void)didExitPreloadState
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  [_interfaceStateDelegate didExitPreloadState];
}

- (void)clearContents
{
  A_SDisplayNodeAssertMainThread();
  if (_flags.canClearContentsOfLayer) {
    // No-op if these haven't been created yet, as that guarantees they don't have contents that needs to be released.
    _layer.contents = nil;
  }
  
  _placeholderLayer.contents = nil;
  _placeholderImage = nil;
}

- (void)recursivelyClearContents
{
  A_SPerformBlockOnMainThread(^{
    A_SDisplayNodePerformBlockOnEveryNode(nil, self, YES, ^(A_SDisplayNode * _Nonnull node) {
      [node clearContents];
    });
  });
}



#pragma mark - Gesture Recognizing

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  // Subclass hook
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  // Subclass hook
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  // Subclass hook
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  // Subclass hook
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  // This method is only implemented on UIView on iOS 6+.
  A_SDisplayNodeAssertMainThread();
  
  // No locking needed as it's main thread only
  UIView *view = _view;
  if (view == nil) {
    return YES;
  }

  // If we reach the base implementation, forward up the view hierarchy.
  UIView *superview = view.superview;
  return [superview gestureRecognizerShouldBegin:gestureRecognizer];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();
  return [_view hitTest:point withEvent:event];
}

- (void)setHitTestSlop:(UIEdgeInsets)hitTestSlop
{
  A_SDN::MutexLocker l(__instanceLock__);
  _hitTestSlop = hitTestSlop;
}

- (UIEdgeInsets)hitTestSlop
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _hitTestSlop;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();
  UIEdgeInsets slop = self.hitTestSlop;
  if (_view && UIEdgeInsetsEqualToEdgeInsets(slop, UIEdgeInsetsZero)) {
    // Safer to use UIView's -pointInside:withEvent: if we can.
    return [_view pointInside:point withEvent:event];
  } else {
    return CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, slop), point);
  }
}


#pragma mark - Pending View State

- (void)_locked_applyPendingStateToViewOrLayer
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(self.nodeLoaded, @"must have a view or layer");

  TIME_SCOPED(_debugTimeToApplyPendingState);
  
  // If no view/layer properties were set before the view/layer were created, _pendingViewState will be nil and the default values
  // for the view/layer are still valid.
  [self _locked_applyPendingViewState];
  
  if (_flags.displaySuspended) {
    self._locked_asyncLayer.displaySuspended = YES;
  }
  if (!_flags.displaysAsynchronously) {
    self._locked_asyncLayer.displaysAsynchronously = NO;
  }
}

- (void)applyPendingViewState
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  A_SDN::MutexLocker l(__instanceLock__);
  // FIXME: Ideally we'd call this as soon as the node receives -setNeedsLayout
  // but automatic subnode management would require us to modify the node tree
  // in the background on a loaded node, which isn't currently supported.
  if (_pendingViewState.hasSetNeedsLayout) {
    // Need to unlock before calling setNeedsLayout to avoid deadlocks.
    // MutexUnlocker will re-lock at the end of scope.
    A_SDN::MutexUnlocker u(__instanceLock__);
    [self __setNeedsLayout];
  }
  
  [self _locked_applyPendingViewState];
}

- (void)_locked_applyPendingViewState
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert([self _locked_isNodeLoaded], @"Expected node to be loaded before applying pending state.");

  if (_flags.layerBacked) {
    [_pendingViewState applyToLayer:_layer];
  } else {
    BOOL specialPropertiesHandling = A_SDisplayNodeNeedsSpecialPropertiesHandling(checkFlag(Synchronous), _flags.layerBacked);
    [_pendingViewState applyToView:_view withSpecialPropertiesHandling:specialPropertiesHandling];
  }

  // _A_SPendingState objects can add up very quickly when adding
  // many nodes. This is especially an issue in large collection views
  // and table views. This needs to be weighed against the cost of
  // reallocing a _A_SPendingState. So in range managed nodes we
  // delete the pending state, otherwise we just clear it.
  if (A_SHierarchyStateIncludesRangeManaged(_hierarchyState)) {
    _pendingViewState = nil;
  } else {
    [_pendingViewState clearChanges];
  }
}

// This method has proved helpful in a few rare scenarios, similar to a category extension on UIView, but assumes knowledge of _A_SDisplayView.
// It's considered private API for now and its use should not be encouraged.
- (A_SDisplayNode *)_supernodeWithClass:(Class)supernodeClass checkViewHierarchy:(BOOL)checkViewHierarchy
{
  A_SDisplayNode *supernode = self.supernode;
  while (supernode) {
    if ([supernode isKindOfClass:supernodeClass])
      return supernode;
    supernode = supernode.supernode;
  }
  if (!checkViewHierarchy) {
    return nil;
  }

  UIView *view = self.view.superview;
  while (view) {
    A_SDisplayNode *viewNode = ((_A_SDisplayView *)view).asyncdisplaykit_node;
    if (viewNode) {
      if ([viewNode isKindOfClass:supernodeClass])
        return viewNode;
    }

    view = view.superview;
  }

  return nil;
}

#pragma mark - Performance Measurement

- (void)setMeasurementOptions:(A_SDisplayNodePerformanceMeasurementOptions)measurementOptions
{
  A_SDN::MutexLocker l(__instanceLock__);
  _measurementOptions = measurementOptions;
}

- (A_SDisplayNodePerformanceMeasurementOptions)measurementOptions
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _measurementOptions;
}

- (A_SDisplayNodePerformanceMeasurements)performanceMeasurements
{
  A_SDN::MutexLocker l(__instanceLock__);
  A_SDisplayNodePerformanceMeasurements measurements = { .layoutSpecNumberOfPasses = -1, .layoutSpecTotalTime = NAN, .layoutComputationNumberOfPasses = -1, .layoutComputationTotalTime = NAN };
  if (_measurementOptions & A_SDisplayNodePerformanceMeasurementOptionLayoutSpec) {
    measurements.layoutSpecNumberOfPasses = _layoutSpecNumberOfPasses;
    measurements.layoutSpecTotalTime = _layoutSpecTotalTime;
  }
  if (_measurementOptions & A_SDisplayNodePerformanceMeasurementOptionLayoutComputation) {
    measurements.layoutComputationNumberOfPasses = _layoutComputationNumberOfPasses;
    measurements.layoutComputationTotalTime = _layoutComputationTotalTime;
  }
  return measurements;
}

#pragma mark - Accessibility

- (void)setIsAccessibilityContainer:(BOOL)isAccessibilityContainer
{
  A_SDN::MutexLocker l(__instanceLock__);
  _isAccessibilityContainer = isAccessibilityContainer;
}

- (BOOL)isAccessibilityContainer
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _isAccessibilityContainer;
}

#pragma mark - Debugging (Private)

#if A_SEVENTLOG_ENABLE
- (A_SEventLog *)eventLog
{
  return _eventLog;
}
#endif

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  A_SPushMainThreadAssertionsDisabled();
  
  NSString *debugName = self.debugName;
  if (debugName.length > 0) {
    [result addObject:@{ (id)kCFNull : A_SStringWithQuotesIfMultiword(debugName) }];
  }

  NSString *axId = self.accessibilityIdentifier;
  if (axId.length > 0) {
    [result addObject:@{ (id)kCFNull : A_SStringWithQuotesIfMultiword(axId) }];
  }

  A_SPopMainThreadAssertionsDisabled();
  return result;
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  
  if (self.debugName.length > 0) {
    [result addObject:@{ @"debugName" : A_SStringWithQuotesIfMultiword(self.debugName)}];
  }
  if (self.accessibilityIdentifier.length > 0) {
    [result addObject:@{ @"axId": A_SStringWithQuotesIfMultiword(self.accessibilityIdentifier) }];
  }

  CGRect windowFrame = [self _frameInWindow];
  if (CGRectIsNull(windowFrame) == NO) {
    [result addObject:@{ @"frameInWindow" : [NSValue valueWithCGRect:windowFrame] }];
  }
  
  // Attempt to find view controller.
  // Note that the convenience method asdk_associatedViewController has an assertion
  // that it's run on main. Since this is a debug method, let's bypass the assertion
  // and run up the chain ourselves.
  if (_view != nil) {
    for (UIResponder *responder in [_view asdk_responderChainEnumerator]) {
      UIViewController *vc = A_SDynamicCast(responder, UIViewController);
      if (vc) {
        [result addObject:@{ @"viewController" : A_SObjectDescriptionMakeTiny(vc) }];
        break;
      }
    }
  }
  
  if (_view != nil) {
    [result addObject:@{ @"alpha" : @(_view.alpha) }];
    [result addObject:@{ @"frame" : [NSValue valueWithCGRect:_view.frame] }];
  } else if (_layer != nil) {
    [result addObject:@{ @"alpha" : @(_layer.opacity) }];
    [result addObject:@{ @"frame" : [NSValue valueWithCGRect:_layer.frame] }];
  } else if (_pendingViewState != nil) {
    [result addObject:@{ @"alpha" : @(_pendingViewState.alpha) }];
    [result addObject:@{ @"frame" : [NSValue valueWithCGRect:_pendingViewState.frame] }];
  }
  
  // Check supernode so that if we are a cell node we don't find self.
  A_SCellNode *cellNode = [self supernodeOfClass:[A_SCellNode class] includingSelf:NO];
  if (cellNode != nil) {
    [result addObject:@{ @"cellNode" : A_SObjectDescriptionMakeTiny(cellNode) }];
  }
  
  [result addObject:@{ @"interfaceState" : NSStringFromA_SInterfaceState(self.interfaceState)} ];
  
  if (_view != nil) {
    [result addObject:@{ @"view" : A_SObjectDescriptionMakeTiny(_view) }];
  } else if (_layer != nil) {
    [result addObject:@{ @"layer" : A_SObjectDescriptionMakeTiny(_layer) }];
  } else if (_viewClass != nil) {
    [result addObject:@{ @"viewClass" : _viewClass }];
  } else if (_layerClass != nil) {
    [result addObject:@{ @"layerClass" : _layerClass }];
  } else if (_viewBlock != nil) {
    [result addObject:@{ @"viewBlock" : _viewBlock }];
  } else if (_layerBlock != nil) {
    [result addObject:@{ @"layerBlock" : _layerBlock }];
  }

#if TIME_DISPLAYNODE_OPS
  NSString *creationTypeString = [NSString stringWithFormat:@"cr8:%.2lfms dl:%.2lfms ap:%.2lfms ad:%.2lfms",  1000 * _debugTimeToCreateView, 1000 * _debugTimeForDidLoad, 1000 * _debugTimeToApplyPendingState, 1000 * _debugTimeToAddSubnodeViews];
  [result addObject:@{ @"creationTypeString" : creationTypeString }];
#endif
  
  return result;
}

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSString *)debugDescription
{
  A_SPushMainThreadAssertionsDisabled();
  auto result = A_SObjectDescriptionMake(self, [self propertiesForDebugDescription]);
  A_SPopMainThreadAssertionsDisabled();
  return result;
}

// This should only be called for debugging. It's not thread safe and it doesn't assert.
// NOTE: Returns CGRectNull if the node isn't in a hierarchy.
- (CGRect)_frameInWindow
{
  if (self.isNodeLoaded == NO || self.isInHierarchy == NO) {
    return CGRectNull;
  }

  if (self.layerBacked) {
    CALayer *rootLayer = _layer;
    CALayer *nextLayer = nil;
    while ((nextLayer = rootLayer.superlayer) != nil) {
      rootLayer = nextLayer;
    }

    return [_layer convertRect:self.threadSafeBounds toLayer:rootLayer];
  } else {
    return [_view convertRect:self.threadSafeBounds toView:nil];
  }
}

#pragma mark - Trait Collection Hooks

- (void)asyncTraitCollectionDidChange
{
  // Subclass override
}

#if TARGET_OS_TV
#pragma mark - UIFocusEnvironment Protocol (tvOS)

- (void)setNeedsFocusUpdate
{
  
}

- (void)updateFocusIfNeeded
{
  
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
  return NO;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
  
}

- (UIView *)preferredFocusedView
{
  if (self.nodeLoaded) {
    return self.view;
  } else {
    return nil;
  }
}
#endif

@end

#pragma mark - A_SDisplayNode (Debugging)

@implementation A_SDisplayNode (Debugging)

+ (void)setShouldStoreUnflattenedLayouts:(BOOL)shouldStore
{
  storesUnflattenedLayouts.store(shouldStore);
}

+ (BOOL)shouldStoreUnflattenedLayouts
{
  return storesUnflattenedLayouts.load();
}

- (A_SLayout *)unflattenedCalculatedLayout
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _unflattenedLayout;
}

- (NSString *)displayNodeRecursiveDescription
{
  return [self _recursiveDescriptionHelperWithIndent:@""];
}

- (NSString *)_recursiveDescriptionHelperWithIndent:(NSString *)indent
{
  NSMutableString *subtree = [[[indent stringByAppendingString:self.debugDescription] stringByAppendingString:@"\n"] mutableCopy];
  for (A_SDisplayNode *n in self.subnodes) {
    [subtree appendString:[n _recursiveDescriptionHelperWithIndent:[indent stringByAppendingString:@" | "]]];
  }
  return subtree;
}

- (NSString *)detailedLayoutDescription
{
  A_SPushMainThreadAssertionsDisabled();
  A_SDN::MutexLocker l(__instanceLock__);
  auto props = [NSMutableArray<NSDictionary *> array];

  [props addObject:@{ @"layoutVersion": @(_layoutVersion.load()) }];
  [props addObject:@{ @"bounds": [NSValue valueWithCGRect:self.bounds] }];

  if (_calculatedDisplayNodeLayout != nullptr) {
    A_SDisplayNodeLayout c = *_calculatedDisplayNodeLayout;
    [props addObject:@{ @"calculatedLayout": c.layout }];
    [props addObject:@{ @"calculatedVersion": @(c.version) }];
    [props addObject:@{ @"calculatedConstrainedSize" : NSStringFromA_SSizeRange(c.constrainedSize) }];
    if (c.requestedLayoutFromAbove) {
      [props addObject:@{ @"calculatedRequestedLayoutFromAbove": @"YES" }];
    }
  }
  if (_pendingDisplayNodeLayout != nullptr) {
    A_SDisplayNodeLayout p = *_pendingDisplayNodeLayout;
    [props addObject:@{ @"pendingLayout": p.layout }];
    [props addObject:@{ @"pendingVersion": @(p.version) }];
    [props addObject:@{ @"pendingConstrainedSize" : NSStringFromA_SSizeRange(p.constrainedSize) }];
    if (p.requestedLayoutFromAbove) {
      [props addObject:@{ @"pendingRequestedLayoutFromAbove": (id)kCFNull }];
    }
  }

  A_SPopMainThreadAssertionsDisabled();
  return A_SObjectDescriptionMake(self, props);
}

@end

#pragma mark - A_SDisplayNode UIKit / CA Categories

// We use associated objects as a last resort if our view is not a _A_SDisplayView ie it doesn't have the _node ivar to write to

static const char *A_SDisplayNodeAssociatedNodeKey = "A_SAssociatedNode";

@implementation UIView (A_SDisplayNodeInternal)

- (void)setAsyncdisplaykit_node:(A_SDisplayNode *)node
{
  A_SWeakProxy *weakProxy = [A_SWeakProxy weakProxyWithTarget:node];
  objc_setAssociatedObject(self, A_SDisplayNodeAssociatedNodeKey, weakProxy, OBJC_ASSOCIATION_RETAIN); // Weak reference to avoid cycle, since the node retains the view.
}

- (A_SDisplayNode *)asyncdisplaykit_node
{
  A_SWeakProxy *weakProxy = objc_getAssociatedObject(self, A_SDisplayNodeAssociatedNodeKey);
  return weakProxy.target;
}

@end

@implementation CALayer (A_SDisplayNodeInternal)

- (void)setAsyncdisplaykit_node:(A_SDisplayNode *)node
{
  A_SWeakProxy *weakProxy = [A_SWeakProxy weakProxyWithTarget:node];
  objc_setAssociatedObject(self, A_SDisplayNodeAssociatedNodeKey, weakProxy, OBJC_ASSOCIATION_RETAIN); // Weak reference to avoid cycle, since the node retains the layer.
}

- (A_SDisplayNode *)asyncdisplaykit_node
{
  A_SWeakProxy *weakProxy = objc_getAssociatedObject(self, A_SDisplayNodeAssociatedNodeKey);
  return weakProxy.target;
}

@end

@implementation UIView (Async_DisplayKit)

- (void)addSubnode:(A_SDisplayNode *)subnode
{
  if (subnode.layerBacked) {
    // Call -addSubnode: so that we use the asyncdisplaykit_node path if possible.
    [self.layer addSubnode:subnode];
  } else {
    A_SDisplayNode *selfNode = self.asyncdisplaykit_node;
    if (selfNode) {
      [selfNode addSubnode:subnode];
    } else {
      if (subnode.supernode) {
        [subnode removeFromSupernode];
      }
      [self addSubview:subnode.view];
    }
  }
}

@end

@implementation CALayer (Async_DisplayKit)

- (void)addSubnode:(A_SDisplayNode *)subnode
{
  A_SDisplayNode *selfNode = self.asyncdisplaykit_node;
  if (selfNode) {
    [selfNode addSubnode:subnode];
  } else {
    if (subnode.supernode) {
      [subnode removeFromSupernode];
    }
    [self addSublayer:subnode.layer];
  }
}

@end
