/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
	// MARK: - IBOutlets

  @IBOutlet weak var sessionInfoView: UIView!
	@IBOutlet weak var sessionInfoLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!

  var activeNode: SCNNode?

	// MARK: - View Life Cycle
	
    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
        */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

      sceneView.autoenablesDefaultLighting = true
      sceneView.automaticallyUpdatesLighting = true

        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
        */
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's AR session.
		sceneView.session.pause()
	}

  override func viewDidLoad() {
    super.viewDidLoad()
    addBox()
    addTapGestureToSceneView()
  }

  func addTapGestureToSceneView() {
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(tapRecognizer)

    let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.didRotate(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(rotateRecognizer)
  }

  @objc func didRotate(withGestureRecognizer recognizer: UIRotationGestureRecognizer) {
    guard recognizer.state == .changed else { return }

    activeNode?.eulerAngles.y -= Float(recognizer.rotation)

    recognizer.rotation = 0
  }

  @objc func didTap(withGestureRecognizer recognizer: UITapGestureRecognizer) {
    let tapLocation = recognizer.location(in: sceneView)
    let hitTestResultsWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)

    if let hitTestResultsWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
      let translation = hitTestResultsWithFeaturePoints.worldTransform.translation
      addBox(x: translation.x, y: translation.y, z: translation.z)
    }
  }

  func addBox(x: Float = 0, y: Float = 0, z: Float = -0.2) {
    let box = SCNBox(width: 0.72, height: 0.42, length: 0.05, chamferRadius: 0)

    let greenMaterial = SCNMaterial()
    greenMaterial.diffuse.contents = #imageLiteral(resourceName: "samsung-tv")
    greenMaterial.locksAmbientWithDiffuse = true;
    let redMaterial = SCNMaterial()
    redMaterial.diffuse.contents = UIColor.red
    redMaterial.locksAmbientWithDiffuse = true;
    let blueMaterial  = SCNMaterial()
    blueMaterial.diffuse.contents = #imageLiteral(resourceName: "samsung-tv")
    blueMaterial.locksAmbientWithDiffuse = true;
    let yellowMaterial = SCNMaterial()
    yellowMaterial.diffuse.contents = UIColor.yellow
    yellowMaterial.locksAmbientWithDiffuse = true;
    let purpleMaterial = SCNMaterial()
    purpleMaterial.diffuse.contents = UIColor.purple
    purpleMaterial.locksAmbientWithDiffuse = true;
    let WhiteMaterial = SCNMaterial()
    WhiteMaterial.diffuse.contents = UIColor.white
    WhiteMaterial.locksAmbientWithDiffuse   = true;

    box.materials = [greenMaterial, redMaterial, blueMaterial, yellowMaterial, purpleMaterial, WhiteMaterial]

    let boxNode = SCNNode()
    boxNode.geometry = box
    boxNode.position = SCNVector3(x, y, z)

    activeNode = boxNode

    sceneView.scene.rootNode.addChildNode(boxNode)
  }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay.
		sessionInfoLabel.text = "Session was interrupted"
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required.
		sessionInfoLabel.text = "Session interruption ended"
		resetTracking()
	}
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }

    // MARK: - Private methods

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."
            
        case .normal:
            // No feedback needed when tracking is normal and planes are visible.
            message = ""
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        }

        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }

    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension float4x4 {
  var translation: float3 {
    let translation = self.columns.3
    return float3(translation.x, translation.y, translation.z)
  }
}
