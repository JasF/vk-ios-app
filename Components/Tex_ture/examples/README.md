# Sample projects

## Building

Run `pod install` in each sample project directory to set up their
dependencies.

## Example Catalog

### A_SCollectionView [ObjC]

![A_SCollectionView Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_SCollectionView.png)
 
Featuring:
- A_SCollectionView with header/footer supplementary node support
- A_SCollectionView batch API
- A_SDelegateProxy

### A_SDKgram [ObjC]

![A_SDKgram Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_SDKgram.png)

### A_SDKLayoutTransition [ObjC]

![A_SDKLayoutTransition Example App](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_SDKLayoutTransition.gif)

### A_SDKTube [ObjC]

![A_SDKTube Example App](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_SDKTube.gif)

### A_SMapNode [ObjC]

![A_SMapNode Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_SMapNode.png)

### A_STableViewStressTest [ObjC]

![A_STableViewStressTest Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_STableViewStressTest.png)

### A_SViewController [ObjC]

![A_SViewController Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/A_SViewController.png)
 
Featuring:
- A_SViewController
- A_STableView
- A_SMultiplexImageNode
- A_SLayoutSpec

### Async_DisplayKitOverview [ObjC]

![Async_DisplayKitOverview Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/Async_DisplayKitOverview.png)

### BackgroundPropertySetting [Swift]

![BackgroundPropertySetting Example App gif](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/BackgroundPropertySetting.gif)
 
Featuring:
- A_SDK Swift compatibility
- A_SViewController
- A_SCollectionView
- thread affinity
- A_SLayoutSpec

### CarthageBuildTest
### CatDealsCollectionView [ObjC]

![CatDealsCollectionView Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/CatDealsCollectionView.png)
 
Featuring:
- A_SCollectionView
- A_SRangeTuningParameters
- Placeholder Images
- A_SLayoutSpec

### CollectionViewWithViewControllerCells [ObjC]

![CollectionViewWithViewControllerCells Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/CollectionViewWithViewControllerCells.png)
 
Featuring:
- custom collection view layout
- A_SLayoutSpec
- A_SMultiplexImageNode

### CustomCollectionView [ObjC+Swift]

![CustomCollectionView Example App gif](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/CustomCollectionView.git)
 
Featuring:
- custom collection view layout
- A_SCollectionView with sections

### EditableText [ObjC]

![EditableText Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/EditableText.png)
 
Featuring:
- A_SEditableTextNode

### HorizontalwithinVerticalScrolling [ObjC]

![HorizontalwithinVerticalScrolling Example App gif](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/HorizontalwithinVerticalScrolling.gif)
 
Featuring:
- UIViewController with A_STableView
- A_SCollectionView
- A_SCellNode

### Kittens [ObjC]

![Kittens Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/Kittens.png)
 
Featuring:
- UIViewController with A_STableView
- A_SCellNodes with A_SNetworkImageNode and A_STextNode

### LayoutSpecPlayground [ObjC]

![LayoutSpecPlayground Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/LayoutSpecPlayground.png)

### Multiplex [ObjC]

![Multiplex Example App](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/Multiplex.gif)
 
Featuring:
- A_SMultiplexImageNode (with artificial delay inserted)
- A_SLayoutSpec

### PagerNode [ObjC]

![PagerNode Example App](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/PagerNode.gif)

Featuring:
- A_SPagerNode

### Placeholders [ObjC]

Featuring:
- A_SDisplayNodes now have an overidable method -placeholderImage that lets you provide a custom UIImage to display while a node is displaying asyncronously. The default implementation of this method returns nil and thus does nothing. A provided example project also demonstrates using the placeholder API.

### SocialAppLayout [ObjC]

![SocialAppLayout Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/SocialAppLayout.png)

Featuring:
- A_SLayoutSpec
- UIViewController with A_STableView

### Swift [Swift]

![Swift Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/Swift.png)

Featuring:
- A_SViewController with A_STableNode

### SynchronousConcurrency [ObjC]

![SynchronousConcurrency Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/SynchronousConcurrency.png)

Implementation of Synchronous Concurrency features for Async_DisplayKit 2.0

This provides internal features on _A_SAsyncTransaction and A_SDisplayNode to facilitate
implementing public API that allows clients to choose if they would prefer to block
on the completion of unfinished rendering, rather than allow a placeholder state to
become visible.

The internal features are:
-[_A_SAsyncTransaction waitUntilComplete]
-[A_SDisplayNode recursivelyEnsureDisplay]

Also provided are two such implementations:
-[A_SCellNode setNeverShowPlaceholders:], which integrates with both Tables and Collections
-[A_SViewController setNeverShowPlaceholders:], which should work with Nav and Tab controllers.

Lastly, on A_SDisplayNode, a new property .shouldBypassEnsureDisplay allows individual node types
to exempt themselves from blocking the main thread on their display.

By implementing the feature at the A_SCellNode level rather than A_STableView & A_SCollectionView,
developers can retain fine-grained control on display characteristics.  For example, certain
cell types may be appropriate to display to the user with placeholders, whereas others may not.

### SynchronousKittens [ObjC]

### VerticalWithinHorizontalScrolling [ObjC]

![VerticalWithinHorizontalScrolling Example App](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/VerticalWithinHorizontalScrolling.gif)

Features:
- UIViewController containing A_SPagerNode containing A_STableNodes

### Videos [ObjC]

![VideoTableView Example App gif](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/Videos.gif)

Featuring:
- A_SVideoNode

### VideoTableView [ObjC]

![VideoTableView Example App Screenshot](https://github.com/Async_DisplayKit/Documentation/raw/master/docs/static/images/example-app-screenshots/VideoTableView.png) 

Featuring:
- A_SVideoNode
- A_STableView
- A_SCellNode

## License

    This file provided by Facebook is for non-commercial testing and evaluation
    purposes only.  Facebook reserves all rights not expressly granted.
    
    THE SOFTWARE IS PROVIDED "A_S IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
