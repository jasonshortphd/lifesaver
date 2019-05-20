//
//  LifeScene.swift
//  Life Saver
//
//  Created by Bradley Root on 5/18/19.
//  Copyright © 2019 Brad Root. All rights reserved.
//

import GameplayKit
import SpriteKit

func randomCGFloat(min: CGFloat, max: CGFloat) -> CGFloat {
    return CGFloat(Float.random(in: Float(min) ... Float(max)))
}

extension SKColor {
    static let aliveColor = SKColor(red: 173 / 255.0, green: 98 / 255.0, blue: 22 / 255.0, alpha: 1.00)
    static let aliveColor1 = SKColor(red: 174 / 255.0, green: 129 / 255.0, blue: 0 / 255.0, alpha: 1.00)
    static let aliveColor2 = SKColor(red: 172 / 255.0, green: 48 / 255.0, blue: 17 / 255.0, alpha: 1.00)
    static let aliveColor3 = SKColor(red: 6 / 255.0, green: 66 / 255.0, blue: 110 / 255.0, alpha: 1.00)
}

class SquareNodeData {
    let x: Int
    let y: Int
    let node: SKSpriteNode
    let label: SKLabelNode
    var alive: Bool {
        didSet {
            label.text = "(\(x), \(y))\n\(alive ? "Alive" : "Dead")"
        }
    }

    var timeInState: Int = 0
    var aliveColor: SKColor

    init(x: Int, y: Int, node: SKSpriteNode, label: SKLabelNode, alive: Bool, aliveColor: SKColor) {
        self.x = x
        self.y = y
        self.node = node
        self.label = label
        self.alive = alive
        self.aliveColor = aliveColor
    }
}

class LifeScene: SKScene {
    private var cameraNode: SKCameraNode = SKCameraNode()
    private var lastUpdate: TimeInterval = 0

    private var squareData: [SquareNodeData] = []
    private var aliveSquareData: [SquareNodeData] = []
    private var deadSquareData: [SquareNodeData] = []

    private var aliveColors: [SKColor] = [.aliveColor, .aliveColor1, .aliveColor2, .aliveColor3]

    private var updateTime: TimeInterval = 1

    override func sceneDidLoad() {
        size.width = frame.size.width * 2
        size.height = frame.size.height * 2
        backgroundColor = SKColor.black
        scaleMode = .fill

        // Try drawing some squares...
        let lengthSquares: CGFloat = 7
        let heightSquares: CGFloat = 7
        let totalSquares: CGFloat = lengthSquares * heightSquares
        let squareWidth: CGFloat = size.width / lengthSquares
        let squareHeight: CGFloat = size.height / heightSquares

        var createdSquares: CGFloat = 0
        var nextXValue: Int = 0
        var nextYValue: Int = 0
        var nextXPosition: CGFloat = 0
        var nextYPosition: CGFloat = 0
        while createdSquares < totalSquares {
            let newSquare = SKSpriteNode(
                texture: FileGrabber.shared.getSKTexture(named: "square"),
                size: CGSize(width: squareWidth, height: squareHeight)
            )
            newSquare.setScale(1)
            newSquare.anchorPoint = CGPoint(x: 0, y: 0)
            newSquare.color = .black
            newSquare.colorBlendFactor = 1
            addChild(newSquare)
            newSquare.zPosition = 0
            newSquare.position = CGPoint(x: nextXPosition, y: nextYPosition)

            let newLabel = SKLabelNode(text: "(\(nextXValue), \(nextYValue))\nDead")
            newLabel.fontColor = .white
            newLabel.numberOfLines = 2
            addChild(newLabel)
            newLabel.zPosition = 1
            newLabel.position = CGPoint(x: newSquare.position.x + (newSquare.size.width / 2), y: newSquare.position.y + (newSquare.size.height / 3))
            newLabel.isHidden = true

            let aliveColor = aliveColors.randomElement()!
            let newSquareData = SquareNodeData(
                x: nextXValue,
                y: nextYValue,
                node: newSquare,
                label: newLabel,
                alive: false,
                aliveColor: aliveColor
            )
            deadSquareData.append(newSquareData)
            squareData.append(newSquareData)

            createdSquares += 1

            if nextXValue == Int(lengthSquares) - 1 {
                nextXValue = 0
                nextXPosition = 0
                nextYValue += 1
                nextYPosition += squareHeight
            } else {
                nextXValue += 1
                nextXPosition += squareWidth
            }
        }
    }

    override func didMove(to _: SKView) {}

    func applyBlur() {
        shouldEnableEffects = true
        shouldCenterFilter = true

        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setDefaults()
        blur?.setValue(150, forKey: "inputRadius")
        shouldRasterize = true

        filter = blur
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 {
            lastUpdate = currentTime
//            applyBlur()
        }

        if currentTime - lastUpdate >= updateTime {
            lastUpdate = currentTime

            var dyingNodes: [SquareNodeData] = []
            var livingNodes: [SquareNodeData] = []
            for nodeData in squareData {
                // Get neighbors...
                let livingNeighbors = aliveSquareData.filter {
                    let delta = (abs(nodeData.x - $0.x), abs(nodeData.y - $0.y))
                    switch delta {
                    case (1, 1), (1, 0), (0, 1):
                        return true
                    default:
                        return false
                    }
                }

                if nodeData.alive {
                    if livingNeighbors.count > 3 || livingNeighbors.count < 2 {
                        dyingNodes.append(nodeData)
                    } else if nodeData.timeInState > 20 {
                        dyingNodes.append(nodeData)
                    } else {
                        livingNodes.append(nodeData)
                    }
                } else if livingNeighbors.count == 3 {
                    nodeData.aliveColor = livingNeighbors.randomElement()!.node.color
                    livingNodes.append(nodeData)
                } else {
                    dyingNodes.append(nodeData)
                }
            }

            while CGFloat(livingNodes.count) < (CGFloat(squareData.count) * 0.08) {
                let nodeNumber = GKRandomSource.sharedRandom().nextInt(upperBound: dyingNodes.count)
                let node = dyingNodes[nodeNumber]
                node.aliveColor = aliveColors.randomElement()!
                livingNodes.append(node)
                dyingNodes.remove(at: nodeNumber)
            }

            livingNodes.forEach {
                if !$0.alive {
                    $0.timeInState = 0
                    $0.node.removeAllActions()
                    $0.alive = true
                    let randomDuration = TimeInterval(randomCGFloat(min: 0.5, max: CGFloat(updateTime)))
                    let fadeAction = SKAction.fadeAlpha(to: 1, duration: randomDuration)
                    let colorAction = SKAction.colorize(with: $0.aliveColor, colorBlendFactor: 1, duration: randomDuration)
                    fadeAction.timingMode = .easeInEaseOut
                    colorAction.timingMode = .easeInEaseOut
                    $0.node.run(fadeAction)
                    $0.node.run(colorAction)
                } else {
                    $0.timeInState += 1
                }
            }

            dyingNodes.forEach {
                if $0.alive {
                    $0.timeInState = 0
                    $0.node.removeAllActions()
                    $0.alive = false
                    let fadeAction = SKAction.fadeAlpha(to: 0.2, duration: updateTime * 5)
                    fadeAction.timingMode = .easeInEaseOut
                    $0.node.run(fadeAction)
                } else {
                    $0.timeInState += 1
                }
            }

            aliveSquareData = livingNodes
            deadSquareData = dyingNodes

        }
    }
}
