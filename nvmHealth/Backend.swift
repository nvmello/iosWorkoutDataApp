//
//  Backend.swift
//  nvmHealth
//
//  Created by Nick Morello on 11/9/24.
//

import Foundation


import SwiftUI
import HealthKit

struct Backend: View {
    @State private var healthStore: HKHealthStore?
    @State private var bodyFatPercentage: Double = 0.0
    @State private var recentWorkout: String = "No recent workout data available"
    
    

    var body: some View {
        VStack(spacing: 20) {

            Text("Most Recent Workout: \(recentWorkout)")
                .font(.title3)
                .padding()
        }
        .onAppear {
            self.healthStore = HKHealthStore()
            Task{
                await self.requestAuthorization();
            }
            
        }
    }

    private func requestAuthorization() async {
        // List of data types we need to read and write.
        let allTypes: Set = [
            HKQuantityType.workoutType(),
//            HKQuantityType(.activeEnergyBurned),
//            HKQuantityType(.distanceCycling),
//            HKQuantityType(.distanceWalkingRunning),
//            HKQuantityType(.distanceWheelchair),
//            HKQuantityType(.heartRate)
        ]
        
        do{
            if HKHealthStore.isHealthDataAvailable(){
                try await healthStore?.requestAuthorization(toShare: [], read: allTypes)
            }
        } catch{
            fatalError("*** An unexpected error occured while requesting authorization: \(error.localizedDescription) ***")
        }
        
    }


//    private func fetchMostRecentWorkout() {
//            
//        }
//    
//    private func startWorkoutObserver() {
//            
//        }
//
//    
//    private func processWorkout(_ workout: HKWorkout) {
//        
//    }
//
//    private func sendWorkoutDataToWebsite(type: String, duration: Double, calories: Double) {
//    }
        
}

extension HKWorkoutActivityType {
    var name2: String {
        switch self {
        case .americanFootball: return "American Football"
        case .archery: return "Archery"
        case .australianFootball: return "Australian Football"
        case .badminton: return "Badminton"
        case .baseball: return "Baseball"
        case .basketball: return "Basketball"
        case .bowling: return "Bowling"
        case .boxing: return "Boxing"
        case .climbing: return "Climbing"
        case .cricket: return "Cricket"
        case .crossTraining: return "Cross Training"
        case .curling: return "Curling"
        case .cycling: return "Cycling"
        case .dance: return "Dance"
        case .elliptical: return "Elliptical"
        case .equestrianSports: return "Equestrian Sports"
        case .fencing: return "Fencing"
        case .fishing: return "Fishing"
        case .functionalStrengthTraining: return "Functional Strength Training"
        case .golf: return "Golf"
        case .gymnastics: return "Gymnastics"
        case .handball: return "Handball"
        case .hiking: return "Hiking"
        case .hockey: return "Hockey"
        case .hunting: return "Hunting"
        case .lacrosse: return "Lacrosse"
        case .martialArts: return "Martial Arts"
        case .mindAndBody: return "Mind and Body"
        case .paddleSports: return "Paddle Sports"
        case .play: return "Play"
        case .preparationAndRecovery: return "Preparation and Recovery"
        case .racquetball: return "Racquetball"
        case .rowing: return "Rowing"
        case .rugby: return "Rugby"
        case .running: return "Running"
        case .sailing: return "Sailing"
        case .skatingSports: return "Skating Sports"
        case .snowSports: return "Snow Sports"
        case .soccer: return "Soccer"
        case .softball: return "Softball"
        case .squash: return "Squash"
        case .stairClimbing: return "Stair Climbing"
        case .surfingSports: return "Surfing Sports"
        case .swimming: return "Swimming"
        case .tableTennis: return "Table Tennis"
        case .tennis: return "Tennis"
        case .trackAndField: return "Track and Field"
        case .traditionalStrengthTraining: return "Traditional Strength Training"
        case .volleyball: return "Volleyball"
        case .walking: return "Walking"
        case .waterFitness: return "Water Fitness"
        case .waterPolo: return "Water Polo"
        case .waterSports: return "Water Sports"
        case .wrestling: return "Wrestling"
        case .yoga: return "Yoga"
        case .barre: return "Barre"
        case .coreTraining: return "Core Training"
        case .crossCountrySkiing: return "Cross Country Skiing"
        case .downhillSkiing: return "Downhill Skiing"
        case .flexibility: return "Flexibility"
        case .highIntensityIntervalTraining: return "High Intensity Interval Training"
        case .jumpRope: return "Jump Rope"
        case .kickboxing: return "Kickboxing"
        case .pilates: return "Pilates"
        case .snowboarding: return "Snowboarding"
        case .stairs: return "Stairs"
        case .stepTraining: return "Step Training"
        case .wheelchairWalkPace: return "Wheelchair Walk Pace"
        case .wheelchairRunPace: return "Wheelchair Run Pace"
        case .taiChi: return "Tai Chi"
        case .mixedCardio: return "Mixed Cardio"
        case .handCycling: return "Hand Cycling"
        case .discSports: return "Disc Sports"
        case .fitnessGaming: return "Fitness Gaming"
        // Add any additional cases here if necessary
        default: return "Other Activity"
        }
    }
}


struct Backend_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
