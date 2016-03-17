//
//  PeerNetworking.swift
//  Overlord
//
//  Created by Brian Lambert on 1/27/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation
import MultipeerConnectivity

// Peer networking class.
class PeerNetworking: NSObject
{
    // The PeerNetworkingDelegate.
    weak var delegate: PeerNetworkingDelegate?

    // The local peer ID key.
    let LocalPeerIDKey = "LocalPeerIDKey"

    // The advertise service type.
    private var advertiseServiceType: String?
    
    // The browse service type.
    private var browseServiceType: String?

    // The local peer identifier.
    private var localPeerID: MCPeerID!
    
    private var localPeerDisplayName: String!
    
    // The session.
    private var session: MCSession!

    // The nearby service advertiser.
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    
    // The nearby service browser.
    private var nearbyServiceBrowser: MCNearbyServiceBrowser!

    // Returns a value which indicates whether peers are connected.
    var peersAreConnected: Bool
    {
        get
        {
            return session.connectedPeers.count != 0
        }
    }

    // Initializer.
    init(advertiseServiceType advertiseServiceTypeIn: String?, browseServiceType browseServiceTypeIn: String?)
    {
        // Initialize.
        advertiseServiceType = advertiseServiceTypeIn
        browseServiceType = browseServiceTypeIn
    }
    
    // Starts.
    func start()
    {
        // Obtain user defaults and see if we have a serialized local peer ID. If we do, deserialize it. If not, make one
        // and serialize it for later use. If we don't serialize and reuse the local peer ID, we'll see duplicates
        // of this local peer in sessions.
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let data = userDefaults.dataForKey(LocalPeerIDKey)
        {
            // Deserialize the local peer ID.
            localPeerID = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! MCPeerID
        }
        else
        {
            // Allocate and initialize a new local peer ID.
            localPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)

            // Serialize and save the peer ID in user defaults.
            let data = NSKeyedArchiver.archivedDataWithRootObject(localPeerID)
            userDefaults.setValue(data, forKey: LocalPeerIDKey)
            userDefaults.synchronize()
        }
        
        // Set the local peer display name.
        localPeerDisplayName = localPeerID.displayName
        
        // Allocate and initialize the session.
        session = MCSession(peer: localPeerID,
            securityIdentity: nil,
            encryptionPreference: .Required)
        session.delegate = self
        
        // Allocate and initialize the nearby service advertizer.
        if let advertiseServiceType = advertiseServiceType
        {
            nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: advertiseServiceType)
            nearbyServiceAdvertiser.delegate = self
        }

        // Allocate and initialize the nearby service browser.
        if let browseServiceType = browseServiceType
        {
            nearbyServiceBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: browseServiceType)
            nearbyServiceBrowser.delegate = self
        }
        
        // Start advertising the local peer and browsing for nearby peers.
        nearbyServiceAdvertiser?.startAdvertisingPeer()
        nearbyServiceBrowser?.startBrowsingForPeers()
        
        // Log.
        log("Started.")
    }
    
    // Stops peer networking.
    func stop()
    {
        // Stop advertising the local peer and browsing for nearby peers.
        nearbyServiceAdvertiser?.stopAdvertisingPeer()
        nearbyServiceBrowser?.stopBrowsingForPeers()
        
        // Disconnect the session.
        session.disconnect()
        
        // Clean up.
        nearbyServiceAdvertiser = nil
        nearbyServiceBrowser = nil
        session = nil
        localPeerID = nil

        // Log.
        log("Stopped.")
    }
    
    // Sends data.
    func sendData(data: NSData) -> Bool
    {
        // If there are no connected peers, we cannot send the data.
        let connectedPeers = session.connectedPeers
        if connectedPeers.count == 0
        {
            // Log.
            log("Unable to send \(data.length) bytes. There are no peers are connected.")
            return false
        }
        
        // There are connected peers. Try to send the data to each of them.
        var errorsOccurred = false
        for peerId in connectedPeers
        {
            // Try to send.
            do
            {
                try session.sendData(data, toPeers: [peerId], withMode: .Reliable)
                log("Sent \(data.length) bytes to peer \(peerId.displayName).")
            }
            catch
            {
                log("Failed to send \(data.length) bytes to peer \(peerId.displayName). Error: \(error).")
                errorsOccurred = true
                break
            }
        }
        
        // Done.
        return !errorsOccurred
    }
}

// MCNearbyServiceAdvertiserDelegate.
extension PeerNetworking: MCNearbyServiceAdvertiserDelegate
{
    // Incoming invitation request.  Call the invitationHandler block with true
    // and a valid session to connect the inviting peer to the session.
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void)
    {
        // Accept the invitation.
        invitationHandler(true, session);
        
        // Log.
        log("Accepted invitation from peer \(peerID.displayName).")
    }
    
    // Advertising did not start due to an error.
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError)
    {
        log("Failed to start advertising. Error: \(error)")
    }
}

// MCSessionDelegate.
extension PeerNetworking: MCNearbyServiceBrowserDelegate
{
    // Found a nearby advertising peer.
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?)
    {
        // Invite the peer to the session.
        nearbyServiceBrowser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 30.0)
        
        // Log.
        log("Found peer \(peerID.displayName) and invited.")
    }
    
    // A nearby peer has stopped advertising.
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID)
    {
        log("Lost peer \(peerID.displayName).")
    }
    
    // Browsing did not start due to an error.
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError)
    {
        log("Failed to start browsing for peers with service type \(browseServiceType). Error: \(error)")
    }
}

// MCSessionDelegate.
extension PeerNetworking: MCSessionDelegate
{
    // Nearby peer changed state.
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState)
    {
        // Log.
        switch state
        {
        case .NotConnected:
            log("Peer \(peerID.displayName) is not connected.")
            
        case .Connecting:
            log("Peer \(peerID.displayName) is connecting.")
            
        case .Connected:
            log("Peer \(peerID.displayName) is connected.")
        }
        
        // Notify the delegate.
        if let delegate = delegate
        {
            delegate.peerNetworkingPeersChanged(self)
        }
    }
    
    // Received data from nearby peer.
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID)
    {
        // Log.
        log("Peer \(peerID.displayName) sent \(data.length) bytes.")
        
        // Notify.
        if let delegate = delegate
        {
            delegate.peerNetworking(self, didReceiveData: data)
        }
    }
    
    // Received a byte stream from nearby peer.
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID)
    {
    }
    
    // Start receiving a resource from nearby peer.
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress)
    {
    }
    
    // Finished receiving a resource from nearby peer and saved the content in a temporary location - the app is responsible for moving the file
    // to a permanent location within its sandbox.
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?)
    {
    }
    
    // Made first contact with peer and have identity information about the nearby peer (certificate may be nil).
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void)
    {
        certificateHandler(true);
        log("Peer \(peerID.displayName) sent certificate and it was accepted.");
    }
}

// Privates.
extension PeerNetworking
{
    // Log.
    private func log(string: String)
    {
        print("PeerNetworking: \(localPeerDisplayName) - \(string)")
    }
}
