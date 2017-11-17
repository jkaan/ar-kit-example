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

  @IBOutlet weak var rightButton: UIButton!
  var activeNode: SCNNode?
  @IBOutlet weak var leftButton: UIButton!

  @IBOutlet weak var inchSizeBox: UILabel!
  let sizes = [
    (height: 0.569, width: 0.9758, length: 0.0626, inchSize: 43),
    (height: 0.6477, width: 1.1079, length: 0.0534, inchSize: 49),
    (height: 0.7105, width: 1.2261, length: 0.0548, inchSize: 55)
  ]

  var activeSize = 0

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
	
  @IBAction func didTapLeft(_ sender: Any) {
    activeNode?.worldPosition = SCNVector3(x: activeNode!.worldPosition.x - 0.10, y: activeNode!.worldPosition.y, z: activeNode!.worldPosition.z)
  }

  @IBAction func didTapRight(_ sender: Any) {
    activeNode?.worldPosition = SCNVector3(x: activeNode!.worldPosition.x + 0.10, y: activeNode!.worldPosition.y, z: activeNode!.worldPosition.z)
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
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)));
    sceneView.addGestureRecognizer(tapRecognizer)

    let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.didRotate(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(rotateRecognizer)

    let panGesture = ThresholdPanGesture(target: self, action: #selector(ViewController.didPan(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(panGesture)
  }

  @objc func didTap(withGestureRecognizer recognizer: UITapGestureRecognizer) {
    toggleBoxSize()
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

  func toggleBoxSize() {
    let box = activeNode?.geometry as! SCNBox

    let size = sizes[activeSize]
    box.height = CGFloat(size.height)
    box.width = CGFloat(size.width)
    box.length = CGFloat(size.length)
    inchSizeBox.text = "\(size.inchSize)\""

    activeSize += 1
    activeSize = activeSize % sizes.count
  }

  func addBox() {
    let box = SCNBox(width: 0.9758, height: 0.569, length: 0.0626, chamferRadius: 0)
    inchSizeBox.text = "43\""

    let greenMaterial = SCNMaterial()
    greenMaterial.diffuse.contents = #imageLiteral(resourceName: "samsung-tv")
    greenMaterial.locksAmbientWithDiffuse = true;
    let redMaterial = SCNMaterial()
    redMaterial.diffuse.contents = UIColor.clear
    redMaterial.locksAmbientWithDiffuse = true;
    let blueMaterial  = SCNMaterial()
    blueMaterial.diffuse.contents = UIColor.black
    blueMaterial.locksAmbientWithDiffuse = true;
    let yellowMaterial = SCNMaterial()
    yellowMaterial.diffuse.contents = UIColor.clear
    yellowMaterial.locksAmbientWithDiffuse = true;
    let purpleMaterial = SCNMaterial()
    purpleMaterial.diffuse.contents = UIColor.clear
    purpleMaterial.locksAmbientWithDiffuse = true;
    let WhiteMaterial = SCNMaterial()
    WhiteMaterial.diffuse.contents = UIColor.clear
    WhiteMaterial.locksAmbientWithDiffuse   = true;

    box.materials = [greenMaterial, redMaterial, blueMaterial, yellowMaterial, purpleMaterial, WhiteMaterial]

    let boxNode = SCNNode()
    boxNode.geometry = box
    boxNode.position = SCNVector3(0, 0, -0.2)

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

