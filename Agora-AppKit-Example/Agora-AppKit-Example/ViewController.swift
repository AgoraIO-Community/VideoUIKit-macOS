//
//  ViewController.swift
//  Agora-AppKit-Example
//
//  Created by Max Cobb on 30/11/2020.
//

import Cocoa
import AgoraUIKit
import AgoraRtcKit

class ViewController: NSViewController {

    var agoraView: AgoraVideoViewer?
    var segmentControl: NSSegmentedControl?
    var userOptionsBtn: AgoraDeviceMenu!
    override func viewDidLoad() {
        super.viewDidLoad()

        let agSettings = AgoraSettings()

        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: <#Agora App ID#>,
                rtcToken: <#Agora Token or nil#>
            ),
            style: .floating,
            agoraSettings: agSettings,
            delegate: self
        )

        agoraView.fills(view: self.view)

        agoraView.join(channel: "test", as: .broadcaster)

        self.agoraView = agoraView
        self.view.setFrameSize(NSSize(width: 1440, height: 790))
        self.chooseCameraButton()
    }

    func chooseCameraButton() {
        self.userOptionsBtn = AgoraDeviceMenu(frame: .zero, pullsDown: true)
        self.userOptionsBtn.delegate = self
        let bounds = self.view.bounds
        userOptionsBtn.frame = .init(origin: CGPoint(x: bounds.width - 160, y: bounds.height - 40), size: CGSize(width: 150, height: 40))
        self.view.addSubview(self.userOptionsBtn)
        userOptionsBtn.autoresizingMask = [.minXMargin, .minYMargin]
    }

    @objc func segmentedControlHit(segc: NSSegmentedControl) {
        let segmentedStyle = [
            AgoraVideoViewer.Style.floating,
            AgoraVideoViewer.Style.grid
        ][segc.indexOfSelectedItem]

        self.agoraView?.style = segmentedStyle
    }

}

extension ViewController: AgoraVideoViewerDelegate {
    func joinedChannel(channel: String) {
        /*
        if self.segmentControl != nil {
            return
        }
        let newControl = NSSegmentedControl(
            labels: ["floating", "grid"], trackingMode: .selectOne, target: self,
            action: #selector(segmentedControlHit)
        )
        newControl.selectedSegment = self.agoraView?.style == .floating ? 0 : 1
        self.view.addSubview(newControl)
        newControl.translatesAutoresizingMaskIntoConstraints = false
        [
            newControl.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10),
            newControl.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10)
        ].forEach { $0.isActive = true }
         */
    }
}

// MARK: Classes for quickly choosing camera or microphone options
// These classes are by no means optimised, only to be used as an example.

extension ViewController: AgoraDeviceMenuDelegate {
    var engine: AgoraRtcEngineKit? {
        self.agoraView?.agkit
    }
}
protocol AgoraDeviceMenuDelegate: NSObject {
    var engine: AgoraRtcEngineKit? { get }
}
class AgoraDeviceMenu: NSPopUpButton {
    public weak var delegate: AgoraDeviceMenuDelegate?
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        self.updateOptionFields()
    }

    func updateOptionFields() {
        while self.numberOfItems > 1 {
            self.removeItem(at: 1)
        }
        let cameraSep = NSMenuItem.separator()
        let cameraTitle = NSMenuItem(title: "Choose Camera", action: #selector(self.changeDevice), keyEquivalent: "")
        cameraTitle.isEnabled = false
        self.menu?.addItem(cameraSep)
        self.menu?.addItem(cameraTitle)
        let cams = self.delegate?.engine?.enumerateDevices(.videoCapture)
        let selectedVideo = self.delegate?.engine?.getDeviceInfo(.videoCapture)
        let selectedAudio = self.delegate?.engine?.getDeviceInfo(.audioRecording)

        for cam in (cams ?? []) {
            let camItem = NSMenuItem(title: cam.deviceName ?? cam.deviceId ?? "unknown", action: #selector(self.changeDevice), keyEquivalent: "")
            camItem.target = self
            camItem.representedObject = cam
            if let deviceId = selectedVideo?.deviceId {
                camItem.state = deviceId == cam.deviceId ? .on : .off
            }
            camItem.indentationLevel = 1
            self.menu?.addItem(camItem)
        }

        let micSep = NSMenuItem.separator()
        let micTitle = NSMenuItem(title: "Choose Microphone", action: #selector(self.changeDevice), keyEquivalent: "")
        micTitle.isEnabled = false
        self.menu?.addItem(micSep)
        self.menu?.addItem(micTitle)
        let mics = self.delegate?.engine?.enumerateDevices(.audioRecording)

        for mic in (mics ?? []) {
            let micItem = NSMenuItem(title: mic.deviceName ?? mic.deviceId ?? "unknown", action: #selector(self.changeDevice), keyEquivalent: "")
            micItem.target = self
            micItem.representedObject = mic
            if let deviceId = selectedAudio?.deviceId {
                micItem.state = deviceId == mic.deviceId ? .on : .off
            }
            micItem.indentationLevel = 1
            self.menu?.addItem(micItem)
        }

    }
    override init(frame buttonFrame: NSRect, pullsDown flag: Bool) {
        super.init(frame: buttonFrame, pullsDown: flag)
        (self.cell as? NSButtonCell)?.backgroundColor = .selectedContentBackgroundColor

        let actionItem = NSMenuItem()
        actionItem.title = "􀣋 Device Settings"
        self.menu?.addItem(actionItem)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func changeDevice(to menuItem: NSMenuItem?) {
        guard menuItem?.state != .on,
              let device = menuItem?.representedObject as? AgoraRtcDeviceInfo,
              let deviceId = device.deviceId
        else {
            return
        }
        self.delegate?.engine?.setDevice(
            device.type, deviceId: deviceId
        )
    }
}
