//
// Copyright (c) 2016 eBay Software Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

//MARK: InputBarView
/**
 InputBarView class for NMessenger.
 Define the input bar for NMessenger. This is where the user would type text and open the camera or photo library.
 */
open class InputBarView: UIView, InputBarViewProtocol {
    
    //MARK: IBOutlets
    //@IBOutlets for input area view
    @IBOutlet open weak var textInputAreaView: UIView!
    //@IBOutlets for input view
    @IBOutlet open weak var textInputView: UITextView!
    
    //MARK: Public Parameters
    
    //MARK: Private Parameters
    //NMessengerViewController where to input is sent to
    open weak var controller:NMessengerViewController!
    
    // MARK: Initialisers
    /**
     Initialiser the view.
     - parameter controller: Must be NMessengerViewController. Sets controller for the view.
     Calls helper method to setup the view
     */
    public required init()
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    public required init(controller:NMessengerViewController) {
        super.init(frame: CGRect.zero)
        self.controller = controller
    }
    /**
     Initialiser the view.
     - parameter controller: Must be NMessengerViewController. Sets controller for the view.
     - parameter controller: Must be CGRect. Sets frame for the view.
     Calls helper method to setup the view
     */
    public required init(controller:NMessengerViewController,frame: CGRect) {
        super.init(frame: frame)
        self.controller = controller
    }
    /**
     - parameter aDecoder: Must be NSCoder
     Calls helper method to setup the view
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
