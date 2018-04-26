//
//  _A_SAsyncTransaction.mm
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

// We need this import for UITrackingRunLoopMode
#import <UIKit/UIApplication.h>

#import <Async_DisplayKit/_A_SAsyncTransaction.h>
#import <Async_DisplayKit/_A_SAsyncTransactionGroup.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SThread.h>
#import <list>
#import <map>
#import <mutex>

#define A_SAsyncTransactionAssertMainThread() NSAssert(0 != pthread_main_np(), @"This method must be called on the main thread");

NSInteger const A_SDefaultTransactionPriority = 0;

@interface A_SAsyncTransactionOperation : NSObject
- (instancetype)initWithOperationCompletionBlock:(asyncdisplaykit_async_transaction_operation_completion_block_t)operationCompletionBlock;
@property (nonatomic, copy) asyncdisplaykit_async_transaction_operation_completion_block_t operationCompletionBlock;
@property (atomic, strong) id value; // set on bg queue by the operation block
@end

@implementation A_SAsyncTransactionOperation

- (instancetype)initWithOperationCompletionBlock:(asyncdisplaykit_async_transaction_operation_completion_block_t)operationCompletionBlock
{
  if ((self = [super init])) {
    _operationCompletionBlock = operationCompletionBlock;
  }
  return self;
}

- (void)dealloc
{
  NSAssert(_operationCompletionBlock == nil, @"Should have been called and released before -dealloc");
}

- (void)callAndReleaseCompletionBlock:(BOOL)canceled;
{
  A_SDisplayNodeAssertMainThread();
  if (_operationCompletionBlock) {
    _operationCompletionBlock(self.value, canceled);
    // Guarantee that _operationCompletionBlock is released on main thread
    _operationCompletionBlock = nil;
  }
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<A_SAsyncTransactionOperation: %p - value = %@>", self, self.value];
}

@end

// Lightweight operation queue for _A_SAsyncTransaction that limits number of spawned threads
class A_SAsyncTransactionQueue
{
public:
  
  // Similar to dispatch_group_t
  class Group
  {
  public:
    // call when group is no longer needed; after last scheduled operation the group will delete itself
    virtual void release() = 0;
    
    // schedule block on given queue
    virtual void schedule(NSInteger priority, dispatch_queue_t queue, dispatch_block_t block) = 0;
    
    // dispatch block on given queue when all previously scheduled blocks finished executing
    virtual void notify(dispatch_queue_t queue, dispatch_block_t block) = 0;
    
    // used when manually executing blocks
    virtual void enter() = 0;
    virtual void leave() = 0;
    
    // wait until all scheduled blocks finished executing
    virtual void wait() = 0;
    
  protected:
    virtual ~Group() { }; // call release() instead
  };
  
  // Create new group
  Group *createGroup();
  
  static A_SAsyncTransactionQueue &instance();
  
private:
  
  struct GroupNotify
  {
    dispatch_block_t _block;
    dispatch_queue_t _queue;
  };
  
  class GroupImpl : public Group
  {
  public:
    GroupImpl(A_SAsyncTransactionQueue &queue)
      : _pendingOperations(0)
      , _releaseCalled(false)
      , _queue(queue)
    {
    }
    
    virtual void release();
    virtual void schedule(NSInteger priority, dispatch_queue_t queue, dispatch_block_t block);
    virtual void notify(dispatch_queue_t queue, dispatch_block_t block);
    virtual void enter();
    virtual void leave();
    virtual void wait();
    
    int _pendingOperations;
    std::list<GroupNotify> _notifyList;
    std::condition_variable _condition;
    BOOL _releaseCalled;
    A_SAsyncTransactionQueue &_queue;
  };
  
  struct Operation
  {
    dispatch_block_t _block;
    GroupImpl *_group;
    NSInteger _priority;
  };
    
  struct DispatchEntry // entry for each dispatch queue
  {
    typedef std::list<Operation> OperationQueue;
    typedef std::list<OperationQueue::iterator> OperationIteratorList; // each item points to operation queue
    typedef std::map<NSInteger, OperationIteratorList> OperationPriorityMap; // sorted by priority

    OperationQueue _operationQueue;
    OperationPriorityMap _operationPriorityMap;
    int _threadCount;
      
    Operation popNextOperation(bool respectPriority);  // assumes locked mutex
    void pushOperation(Operation operation);           // assumes locked mutex
  };
  
  std::map<dispatch_queue_t, DispatchEntry> _entries;
  std::mutex _mutex;
};

A_SAsyncTransactionQueue::Group* A_SAsyncTransactionQueue::createGroup()
{
  Group *res = new GroupImpl(*this);
  return res;
}

void A_SAsyncTransactionQueue::GroupImpl::release()
{
  std::lock_guard<std::mutex> l(_queue._mutex);
  
  if (_pendingOperations == 0)  {
    delete this;
  } else {
    _releaseCalled = YES;
  }
}

A_SAsyncTransactionQueue::Operation A_SAsyncTransactionQueue::DispatchEntry::popNextOperation(bool respectPriority)
{
  NSCAssert(!_operationQueue.empty() && !_operationPriorityMap.empty(), @"No scheduled operations available");

  OperationQueue::iterator queueIterator;
  OperationPriorityMap::iterator mapIterator;
  
  if (respectPriority) {
    mapIterator = --_operationPriorityMap.end();  // highest priority "bucket"
    queueIterator = *mapIterator->second.begin();
  } else {
    queueIterator = _operationQueue.begin();
    mapIterator = _operationPriorityMap.find(queueIterator->_priority);
  }
  
  // no matter what, first item in "bucket" must match item in queue
  NSCAssert(mapIterator->second.front() == queueIterator, @"Queue inconsistency");
  
  Operation res = *queueIterator;
  _operationQueue.erase(queueIterator);
  
  mapIterator->second.pop_front();
  if (mapIterator->second.empty()) {
    _operationPriorityMap.erase(mapIterator);
  }

  return res;
}

void A_SAsyncTransactionQueue::DispatchEntry::pushOperation(A_SAsyncTransactionQueue::Operation operation)
{
  _operationQueue.push_back(operation);

  OperationIteratorList &list = _operationPriorityMap[operation._priority];
  list.push_back(--_operationQueue.end());
}

void A_SAsyncTransactionQueue::GroupImpl::schedule(NSInteger priority, dispatch_queue_t queue, dispatch_block_t block)
{
  A_SAsyncTransactionQueue &q = _queue;
  std::lock_guard<std::mutex> l(q._mutex);
  
  DispatchEntry &entry = q._entries[queue];
  
  Operation operation;
  operation._block = block;
  operation._group = this;
  operation._priority = priority;
  entry.pushOperation(operation);
  
  ++_pendingOperations; // enter group
  
#if A_SDISPLAYNODE_DELAY_DISPLAY
  NSUInteger maxThreads = 1;
#else 
  NSUInteger maxThreads = [NSProcessInfo processInfo].activeProcessorCount * 2;

  // Bit questionable maybe - we can give main thread more CPU time during tracking;
  if ([[NSRunLoop mainRunLoop].currentMode isEqualToString:UITrackingRunLoopMode])
    --maxThreads;
#endif
  
  if (entry._threadCount < maxThreads) { // we need to spawn another thread

    // first thread will take operations in queue order (regardless of priority), other threads will respect priority
    bool respectPriority = entry._threadCount > 0;
    ++entry._threadCount;
    
    dispatch_async(queue, ^{
      std::unique_lock<std::mutex> lock(q._mutex);
      
      // go until there are no more pending operations
      while (!entry._operationQueue.empty()) {
        Operation operation = entry.popNextOperation(respectPriority);
        lock.unlock();
        if (operation._block) {
          operation._block();
        }
        operation._group->leave();
        operation._block = nil; // the block must be freed while mutex is unlocked
        lock.lock();
      }
      --entry._threadCount;
      
      if (entry._threadCount == 0) {
        NSCAssert(entry._operationQueue.empty() || entry._operationPriorityMap.empty(), @"No working threads but operations are still scheduled"); // this shouldn't happen
        q._entries.erase(queue);
      }
    });
  }
}

void A_SAsyncTransactionQueue::GroupImpl::notify(dispatch_queue_t queue, dispatch_block_t block)
{
  std::lock_guard<std::mutex> l(_queue._mutex);

  if (_pendingOperations == 0) {
    dispatch_async(queue, block);
  } else {
    GroupNotify notify;
    notify._block = block;
    notify._queue = queue;
    _notifyList.push_back(notify);
  }
}

void A_SAsyncTransactionQueue::GroupImpl::enter()
{
  std::lock_guard<std::mutex> l(_queue._mutex);
  ++_pendingOperations;
}

void A_SAsyncTransactionQueue::GroupImpl::leave()
{
  std::lock_guard<std::mutex> l(_queue._mutex);
  --_pendingOperations;
  
  if (_pendingOperations == 0) {
    std::list<GroupNotify> notifyList;
    _notifyList.swap(notifyList);
    
    for (GroupNotify & notify : notifyList) {
      dispatch_async(notify._queue, notify._block);
    }
    
    _condition.notify_one();
    
    // there was attempt to release the group before, but we still
    // had operations scheduled so now is good time
    if (_releaseCalled) {
      delete this;
    }
  }
}

void A_SAsyncTransactionQueue::GroupImpl::wait()
{
  std::unique_lock<std::mutex> lock(_queue._mutex);
  while (_pendingOperations > 0) {
    _condition.wait(lock);
  }
}

A_SAsyncTransactionQueue & A_SAsyncTransactionQueue::instance()
{
  static A_SAsyncTransactionQueue *instance = new A_SAsyncTransactionQueue();
  return *instance;
}

@interface _A_SAsyncTransaction ()
@property (atomic) A_SAsyncTransactionState state;
@end


@implementation _A_SAsyncTransaction
{
  A_SAsyncTransactionQueue::Group *_group;
  NSMutableArray<A_SAsyncTransactionOperation *> *_operations;
}

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithCompletionBlock:(void(^)(_A_SAsyncTransaction *, BOOL))completionBlock
{
  if ((self = [self init])) {
    _completionBlock = completionBlock;
    self.state = A_SAsyncTransactionStateOpen;
  }
  return self;
}

- (void)dealloc
{
  // Uncommitted transactions break our guarantees about releasing completion blocks on callbackQueue.
  NSAssert(self.state != A_SAsyncTransactionStateOpen, @"Uncommitted A_SAsyncTransactions are not allowed");
  if (_group) {
    _group->release();
  }
}

#pragma mark - Transaction Management

- (void)addAsyncOperationWithBlock:(asyncdisplaykit_async_transaction_async_operation_block_t)block
                             queue:(dispatch_queue_t)queue
                        completion:(asyncdisplaykit_async_transaction_operation_completion_block_t)completion
{
  [self addAsyncOperationWithBlock:block
                          priority:A_SDefaultTransactionPriority
                             queue:queue
                        completion:completion];
}

- (void)addAsyncOperationWithBlock:(asyncdisplaykit_async_transaction_async_operation_block_t)block
                          priority:(NSInteger)priority
                             queue:(dispatch_queue_t)queue
                        completion:(asyncdisplaykit_async_transaction_operation_completion_block_t)completion
{
  A_SAsyncTransactionAssertMainThread();
  NSAssert(self.state == A_SAsyncTransactionStateOpen, @"You can only add operations to open transactions");

  [self _ensureTransactionData];

  A_SAsyncTransactionOperation *operation = [[A_SAsyncTransactionOperation alloc] initWithOperationCompletionBlock:completion];
  [_operations addObject:operation];
  _group->schedule(priority, queue, ^{
    @autoreleasepool {
      if (self.state != A_SAsyncTransactionStateCanceled) {
        _group->enter();
        block(^(id value){
          operation.value = value;
          _group->leave();
        });
      }
    }
  });
}

- (void)addOperationWithBlock:(asyncdisplaykit_async_transaction_operation_block_t)block
                        queue:(dispatch_queue_t)queue
                   completion:(asyncdisplaykit_async_transaction_operation_completion_block_t)completion
{
    [self addOperationWithBlock:block
                       priority:A_SDefaultTransactionPriority
                          queue:queue
                     completion:completion];
}

- (void)addOperationWithBlock:(asyncdisplaykit_async_transaction_operation_block_t)block
                     priority:(NSInteger)priority
                        queue:(dispatch_queue_t)queue
                   completion:(asyncdisplaykit_async_transaction_operation_completion_block_t)completion
{
  A_SAsyncTransactionAssertMainThread();
  NSAssert(self.state == A_SAsyncTransactionStateOpen, @"You can only add operations to open transactions");

  [self _ensureTransactionData];

  A_SAsyncTransactionOperation *operation = [[A_SAsyncTransactionOperation alloc] initWithOperationCompletionBlock:completion];
  [_operations addObject:operation];
  _group->schedule(priority, queue, ^{
    @autoreleasepool {
      if (self.state != A_SAsyncTransactionStateCanceled) {
        operation.value = block();
      }
    }
  });
}

- (void)addCompletionBlock:(asyncdisplaykit_async_transaction_completion_block_t)completion
{
  __weak __typeof__(self) weakSelf = self;
  dispatch_queue_t bsQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  [self addOperationWithBlock:^(){return (id)nil;} queue:bsQueue completion:^(id value, BOOL canceled) {
    __typeof__(self) strongSelf = weakSelf;
    completion(strongSelf, canceled);
  }];
}

- (void)cancel
{
  A_SAsyncTransactionAssertMainThread();
  NSAssert(self.state != A_SAsyncTransactionStateOpen, @"You can only cancel a committed or already-canceled transaction");
  self.state = A_SAsyncTransactionStateCanceled;
}

- (void)commit
{
  A_SAsyncTransactionAssertMainThread();
  NSAssert(self.state == A_SAsyncTransactionStateOpen, @"You cannot double-commit a transaction");
  self.state = A_SAsyncTransactionStateCommitted;
  
  if ([_operations count] == 0) {
    // Fast path: if a transaction was opened, but no operations were added, execute completion block synchronously.
    if (_completionBlock) {
      _completionBlock(self, NO);
    }
  } else {
    NSAssert(_group != NULL, @"If there are operations, dispatch group should have been created");
    
    _group->notify(dispatch_get_main_queue(), ^{
      [self completeTransaction];
    });
  }
}

- (void)completeTransaction
{
  A_SAsyncTransactionAssertMainThread();
  A_SAsyncTransactionState state = self.state;
  if (state != A_SAsyncTransactionStateComplete) {
    BOOL isCanceled = (state == A_SAsyncTransactionStateCanceled);
    for (A_SAsyncTransactionOperation *operation in _operations) {
      [operation callAndReleaseCompletionBlock:isCanceled];
    }
    
    // Always set state to Complete, even if we were cancelled, to block any extraneous
    // calls to this method that may have been scheduled for the next runloop
    // (e.g. if we needed to force one in this runloop with -waitUntilComplete, but another was already scheduled)
    self.state = A_SAsyncTransactionStateComplete;

    if (_completionBlock) {
      _completionBlock(self, isCanceled);
    }
  }
}

- (void)waitUntilComplete
{
  A_SAsyncTransactionAssertMainThread();
  if (self.state != A_SAsyncTransactionStateComplete) {
    if (_group) {
      _group->wait();
      
      // At this point, the asynchronous operation may have completed, but the runloop
      // observer has not committed the batch of transactions we belong to.  It's important to
      // commit ourselves via the group to avoid double-committing the transaction.
      // This is only necessary when forcing display work to complete before allowing the runloop
      // to continue, e.g. in the implementation of -[A_SDisplayNode recursivelyEnsureDisplay].
      if (self.state == A_SAsyncTransactionStateOpen) {
        [_A_SAsyncTransactionGroup commit];
        NSAssert(self.state != A_SAsyncTransactionStateOpen, @"Transaction should not be open after committing group");
      }
      // If we needed to commit the group above, -completeTransaction may have already been run.
      // It is designed to accommodate this by checking _state to ensure it is not complete.
      [self completeTransaction];
    }
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_ensureTransactionData
{
  // Lazily initialize _group and _operations to avoid overhead in the case where no operations are added to the transaction
  if (_group == NULL) {
    _group = A_SAsyncTransactionQueue::instance().createGroup();
  }
  if (_operations == nil) {
    _operations = [[NSMutableArray alloc] init];
  }
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<_A_SAsyncTransaction: %p - _state = %lu, _group = %p, _operations = %@>", self, (unsigned long)self.state, _group, _operations];
}

@end
