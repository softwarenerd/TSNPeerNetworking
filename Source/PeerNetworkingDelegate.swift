//
//  PeerNetworkingDelegate.swift
//  Overlord
//
//  Created by Brian Lambert on 1/27/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation

// PeerNetworkingDelegate protocol.
protocol PeerNetworkingDelegate: class
{
    // Notifies the delegate that peers changed.
    func peerNetworkingPeersChanged(peerNetworking: PeerNetworking)
    
    // Notifies the delegate that data was received.
    func peerNetworking(peerNetworking: PeerNetworking, didReceiveData data: NSData)
}