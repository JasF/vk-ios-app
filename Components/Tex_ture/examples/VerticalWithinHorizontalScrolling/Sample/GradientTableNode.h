//
//  GradientTableNode.h
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "A_S IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Async_DisplayKit/Async_DisplayKit.h>

/**
 * This A_SCellNode contains an A_STableNode.  It intelligently interacts with a containing A_SCollectionView,
 * to preload and clean up contents as the user scrolls around both vertically and horizontally — in a way that minimizes memory usage.
 */
@interface GradientTableNode : A_SCellNode 

- (instancetype)initWithElementSize:(CGSize)size;

@property (nonatomic) NSInteger pageNumber;

@end
