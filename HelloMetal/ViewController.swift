//
//  ViewController.swift
//  HelloMetal
//
//  Created by Chris Jungmann on 2/3/16.
//  Copyright © 2016 Chris Jungmann. All rights reserved.
//
//  Based on Ray Wenderlich's tutorial
//  http://www.raywenderlich.com/77488/ios-8-metal-tutorial-swift-getting-started
//

import UIKit
import Metal
import QuartzCore           // had to set to Generic iOS Device for this to import properly
                            // http://www.raywenderlich.com/forums/viewtopic.php?f=20&t=18159&start=40


class ViewController: UIViewController {
    
    // define the MTLDevice
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    
    // define a shape
    let vertexData:[Float] = [
         0.0,  1.0, 0.0,
        -1.0, -1.0, 0.0,
         1.0, -1.0, 0.0 ]
    
    // define a vertex buffer
    var vertexBuffer: MTLBuffer! = nil

    // used for render pipeline
    var pipelineState: MTLRenderPipelineState! = nil

    // last step is to create a command queue to control the pipeline
    var commandQueue: MTLCommandQueue! = nil
    
    // used to render
    var timer: CADisplayLink! = nil
    
    // this was missing from the tutorial
//    var drawable = metalLayer.nextDrawable()
    
    // viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 1: initialize the metal device
        device = MTLCreateSystemDefaultDevice()
        
        // Step 2: configure CAMetal Layer
        metalLayer = CAMetalLayer()          // 1
        metalLayer.device = device           // 2
        metalLayer.pixelFormat = .BGRA8Unorm // 3
        metalLayer.framebufferOnly = true    // 4
        metalLayer.frame = view.layer.frame  // 5
        view.layer.addSublayer(metalLayer)   // 6
        
        // Step 3: configure your vertex
        // get size by multiplying the size of the first element by the count of elements in the array
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        // assign to the buffer
        
        // fixed error here with nil not being an acceptable parameter for 'options'
        // http://stackoverflow.com/questions/29584463/ios-8-3-metal-found-nil-while-unwrapping-an-optional-value
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        
        // step 4-5: create a vertex shader & fragment shader
        // A vertex shader is simply a tiny program that runs on the GPU, written in a C++-like language called the Metal Shading Language.
        // NOTE: A vertex shader is called once per vertex
        // See Shaders.metal file
        
        // step 6: Combine vertex shader and fragment shader (along with some other configuration data) into a special object called the render pipeline.
        
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        
        // http://www.raywenderlich.com/forums/viewtopic.php?f=20&t=18159&start=30
//        pipelineStateDescriptor.colorAttachments.objectAtIndexedSubscript(0).pixelFormat = .BGRA8Unorm
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm

        // http://www.raywenderlich.com/forums/viewtopic.php?f=20&t=18159&start=40
//        var pipelineError : NSError?
//        pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor, error: &pipelineError)
        //        if pipelineState == nil {
        //            println("Failed to create pipeline state, error \(pipelineError)")
        //        }
        do {
            pipelineState = try device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch {
            print("error with device.newRenderPipelineStateWithDescriptor")
        }
        
        // Step 7: Create a Command Queue
        commandQueue = device.newCommandQueue()             // wow do I !miss [[thing alloc] init];
        
        // Now we can render
        // Render Step 1:
        // Create a display link with 'timer' of type CADisplayLink
        timer = CADisplayLink(target: self, selector: Selector("gameloop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // render function called by gameloop timed function
    func render() {
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        // this was missing from the tutorial
        // http://www.raywenderlich.com/forums/viewtopic.php?f=20&t=18159&start=30
        let drawable = metalLayer.nextDrawable()

//        renderPassDescriptor.colorAttachments.objectAtIndexedSubscript(0).texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].texture = drawable?.texture

//        renderPassDescriptor.colorAttachments.objectAtIndexedSubscript(0).loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear

//        renderPassDescriptor.colorAttachments.objectAtIndexedSubscript(0).clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        // create command buffer
        let commandBuffer = commandQueue.commandBuffer()
        
        // To create a render command, you use a helper object called a render command encoder
        // let renderEncoderOpt = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
//        if let renderEncoder = renderEncoderOpt {
//            renderEncoder.setRenderPipelineState(pipelineState)
//            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
//            renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
//            renderEncoder.endEncoding()
//        }
        
        // renderCommandEncoderWithDescriptor does not return an optional, so ...
        // http://stackoverflow.com/questions/34124474/swift-to-swift-2-guard-let/34124545
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
        
        // last step
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
        
    }
    
    // used by timer
    // gameloop() simply calls render() each frame
    func gameloop() {
        autoreleasepool {
            self.render()
        }
    }


}

