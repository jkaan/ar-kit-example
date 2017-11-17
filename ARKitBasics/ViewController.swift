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
	@IBOutlet weak var sceneView: VirtualObjectARView!

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
      sceneView.delegate = self

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

    let panGesture = ThresholdPanGesture(target: self, action: #selector(ViewController.didPan(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(panGesture)
  }

  @objc func didRotate(withGestureRecognizer recognizer: UIRotationGestureRecognizer) {
    guard recognizer.state == .changed else { return }

    activeNode?.eulerAngles.y -= Float(recognizer.rotation)

    recognizer.rotation = 0
  }

  @objc func didPan(withGestureRecognizer recognizer: ThresholdPanGesture) {
    switch recognizer.state {
    case .began:
      break
    case .changed where recognizer.isThresholdExceeded:
      guard let object = activeNode else { return }
      let translation = recognizer.translation(in: sceneView)

      let currentPosition = CGPoint(sceneView.projectPoint(object.position))

      // The `currentTrackingPosition` is used to update the `selectedObject` in `updateObjectToCurrentTrackingPosition()`.
      let currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
      recognizer.setTranslation(.zero, in: sceneView)

      translate(object, basedOn: currentTrackingPosition, infinitePlane: true)
    case .changed:
      // Ignore changes to the pan gesture until the threshold for displacment has been exceeded.
      break

    default:
      break
    }
  }

  private func translate(_ object: SCNNode, basedOn screenPos: CGPoint, infinitePlane: Bool) {
    guard let (position, _, _) = sceneView.worldPosition(fromScreenPosition: screenPos,
                                                             objectPosition: object.simdPosition,
                                                             infinitePlane: infinitePlane) else { return }

    /*
     Plane hit test results are generally smooth. If we did *not* hit a plane,
     smooth the movement to prevent large jumps.
     */
    object.position = SCNVector3(x: position.x, y: position.y, z: position.z)
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

