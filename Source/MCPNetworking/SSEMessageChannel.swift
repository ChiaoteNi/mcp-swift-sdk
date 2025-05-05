//
//  SSEMessageChannel.swift
//  MCP
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.

import Foundation

/// MessageChannel implementation that uses Server-Sent Events (SSE)
public final class SSEMessageChannel: MessageChannelProtocol {
    private let serverURL: URL
    private var eventSource: URLSessionDataTask?
    private var session: URLSession
    private var lastEventID: String?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var reconnectInterval: TimeInterval = 3.0 // 3 seconds
    
    /// Closure invoked when new data is received
    public var onReceive: ((Data) -> Void)?
    
    /// Creates a new SSE-based message channel
    /// - Parameter serverURL: The SSE endpoint URL
    public init(serverURL: URL) {
        self.serverURL = serverURL
        self.session = URLSession(configuration: .default)
        connect()
    }
    
    deinit {
        disconnect()
    }

    public func start() {
        connect()
    }

    public func stop() {
        disconnect()
    }
    
    /// Connects to the SSE endpoint
    private func connect() {
        guard !isConnected else { return }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        if let lastEventID = lastEventID {
            request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID")
        }
        
        eventSource = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("SSE connection error: \(error.localizedDescription)")
                self.scheduleReconnect()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                self.scheduleReconnect()
                return
            }
            
            if httpResponse.statusCode == 200 {
                self.isConnected = true
                if let data = data {
                    self.parseSSEData(data)
                }
            } else {
                print("HTTP Error: \(httpResponse.statusCode)")
                self.scheduleReconnect()
            }
        }
        
        eventSource?.resume()
    }
    
    /// Schedules a reconnection attempt
    private func scheduleReconnect() {
        self.isConnected = false
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    /// Disconnects from the SSE endpoint
    private func disconnect() {
        eventSource?.cancel()
        eventSource = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    /// Parses SSE data format
    /// Format: "event: type\ndata: JSON\n\n"
    private func parseSSEData(_ data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        // Split events by double newlines
        let events = text.components(separatedBy: "\n\n")
        
        for event in events where !event.isEmpty {
            var eventName: String?
            var eventData: String?
            var eventID: String?
            
            // Parse each line of the event
            for line in event.components(separatedBy: "\n") where !line.isEmpty {
                if line.hasPrefix("event:") {
                    eventName = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("data:") {
                    eventData = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("id:") {
                    eventID = line.replacingOccurrences(of: "id:", with: "").trimmingCharacters(in: .whitespaces)
                    self.lastEventID = eventID
                }
            }
            
            // Process the event data
            if let eventData = eventData, let data = eventData.data(using: .utf8) {
                self.onReceive?(data)
            }
        }
    }
    
    // MARK: - MessageChannelProtocol
    
    /// Writes data to the SSE server (not supported in standard SSE)
    public func write(_ data: Data) {
        // SSE is one-way by default - this would require a separate HTTP request
        sendDataToServer(data)
    }
    
    /// Writes a string to the SSE server (not supported in standard SSE)
    public func writeLine(_ string: String) {
        if let data = string.data(using: .utf8) {
            write(data)
        }
    }
    
    /// Sends data back to the server using a separate HTTP request
    private func sendDataToServer(_ data: Data) {
        // Create a separate HTTP POST request to send data back
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error sending data to server: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
} 
