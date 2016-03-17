//
//  TSNPeerNetworkingDelegate.swift
//  TSNPeerNetworking
//
//  Created by Brian Lambert on 1/27/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation

// TSNPeerNetworkingDelegate protocol.
public protocol TSNPeerNetworkingDelegate: class
{
    // Notifies the delegate that peers changed.
    func peerNetworkingPeersChanged(peerNetworking: TSNPeerNetworking)
    
    // Notifies the delegate that data was received.
    func peerNetworking(peerNetworking: TSNPeerNetworking, didReceiveData data: NSData)
}