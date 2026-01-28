//
//  AI.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import FoundationModels

class AIExpandHelper {
    static func generatePaintingDescription() -> String {
        // TODO: 这个后期需要接入AI

        return randomPaintingDescription()
    }

    private static func randomPaintingDescription() -> String {
        let subjects = [
            "a lonely traveler walking through an endless landscape",
            "a floating island suspended in the sky",
            "a futuristic city illuminated at night",
            "a quiet forest lake surrounded by mist",
            "an ancient castle standing on a cliff",
            "a mysterious figure wearing a long cloak",
            "a cybernetic girl with glowing eyes",
            "a surreal desert with towering rock formations",
            "a small village hidden in the mountains",
            "a lone spaceship drifting in deep space"
        ]

        let styles = [
            "oil painting",
            "watercolor illustration",
            "digital concept art",
            "cinematic realism",
            "fantasy art",
            "cyberpunk style",
            "impressionist painting",
            "surrealism",
            "dark fantasy",
            "anime-inspired illustration"
        ]

        let lighting = [
            "soft sunset lighting",
            "dramatic cinematic lighting",
            "neon lights reflecting on wet surfaces",
            "volumetric lighting through fog",
            "moody low-key lighting",
            "golden hour light",
            "cold blue ambient light",
            "high contrast light and shadow",
            "backlighting with glowing edges",
            "ethereal light rays"
        ]

        let mood = [
            "a calm and dreamy atmosphere",
            "a mysterious and lonely mood",
            "a warm and peaceful feeling",
            "a dark and melancholic tone",
            "an epic and majestic mood",
            "a surreal and otherworldly feeling",
            "a futuristic and cold atmosphere",
            "a nostalgic and emotional tone",
            "a magical and enchanting mood",
            "a dramatic and intense atmosphere"
        ]

        let details = [
            "highly detailed",
            "ultra high resolution",
            "intricate details",
            "sharp focus",
            "soft depth of field",
            "wide angle composition",
            "centered composition",
            "dynamic perspective",
            "cinematic composition",
            "beautiful color grading"
        ]

        let parts = [
            subjects.randomElement()!,
            "in \(styles.randomElement()!) style",
            "with \(lighting.randomElement()!)",
            "creating \(mood.randomElement()!)",
            details.randomElement()!
        ]

        return parts.joined(separator: ", ") + "."
    }
}
