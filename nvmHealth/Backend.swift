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
            HKQuantityType.workoutType()
            
        ]
        
        do{
            if HKHealthStore.isHealthDataAvailable(){
                try await healthStore?.requestAuthorization(toShare: [], read: allTypes)
            }
        } catch{
            fatalError("*** An unexpected error occured while requesting authorization: \(error.localizedDescription) ***")
        }
        
        startWorkoutObserver();
        
    }
    
    
    
    private func startWorkoutObserver() {
        guard let healthStore = self.healthStore else { return };
        let workoutType = HKObjectType.workoutType();
        
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) {
            success,
            error in
            if let error = error {
                print("Failed to enable background delivery: \(error.localizedDescription)")
            } else if success {
                print("Background delivery enabled successfully!")
                let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { (
                    query,
                    completionHandler,
                    errorOrNil
                ) in
                    
                    if let error = errorOrNil {
                        print("Observer query failed: \(error.localizedDescription)")
                        return
                    }
                    print("New workout detected.")
                    self.fetchMostRecentWorkout()
                    
                    // If you have subscribed for background updates you must call the completion handler here.
                    completionHandler()
                }
                healthStore.execute(query)
                
                print("Observer query started: \(query.description)")
            }
        }
        
        
    }
    
//    private func fetchLast20Workouts() {
//        guard let healthStore = self.healthStore else { return }
//        let workoutType = HKObjectType.workoutType()
//        
//        // Fetch the last 20 workouts, sorted by end date
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
//        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 20, sortDescriptors: [sortDescriptor]) { query, results, error in
//            guard let workouts = results as? [HKWorkout] else {
//                if let error = error {
//                    print("Error fetching workouts: \(error.localizedDescription)")
//                } else {
//                    print("No workouts found.")
//                }
//                return
//            }
//            
//            // Process each workout
//            DispatchQueue.main.async {
//                workouts.forEach { workout in
//                    self.processWorkout(workout)
//                }
//            }
//        }
//        
//        healthStore.execute(query)
//    }
    
    private func fetchMostRecentWorkout() {
        guard let healthStore = self.healthStore else { return };
        let workoutType = HKObjectType.workoutType();
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) {
            query, results, error in
            
            guard let workout = results?.first as? HKWorkout else {
                if let error = error {
                    print("Error fetching workout: \(error.localizedDescription)")
                } else {
                    print("No recent workout data available.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.processWorkout(workout)
            }
        }
            
        healthStore.execute(query)

    }

    struct WorkoutRecord: Codable{
        let id: UUID                    // workout.UUID
        let type: String               // workout.workoutActivityType.name
        let startDate: Date            // workout.startDate
        let endDate: Date              // workout.endDate
        let duration: Double           // workout.duration
        let calories: Double           // workout.totalEnergyBurned
        let distance: Double?          // workout.totalDistance (optional)
        let elevationGain: Double?     // workout.totalFlightsClimbed (optional)
        
        // Custom coding keys for proper field names in MongoDB
        enum CodingKeys: String, CodingKey {
            case id = "_id"  // MongoDB typically uses _id
            case type
            case startDate = "start_date"
            case endDate = "end_date"
            case duration
            case calories
            case distance
            case elevationGain = "elevation_gain"
        }
    }
    
    private func processWorkout(_ workout: HKWorkout) {
        let workoutRecord = WorkoutRecord(
            id: workout.uuid,
            type: workout.workoutActivityType.name,
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration / 60, // Converting to minutes
            calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
            distance: workout.totalDistance?.doubleValue(for: .mile()) ?? nil, // or .kilometer()
            elevationGain: workout.totalFlightsClimbed?.doubleValue(for: .count()) ?? nil
        )
        
        print("Workout: \(workoutRecord)")
        sendWorkoutDataToWebsite(workoutRecord: workoutRecord)
        
    }
    
    

    private func sendWorkoutDataToWebsite(workoutRecord: WorkoutRecord) {
        guard let url = URL(string: "http://192.168.12.113:3000/api/workouts") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let workoutData: [String: Any?] = [
            "id": workoutRecord.id.uuidString,  // Convert UUID to String
            "type": workoutRecord.type,
            "start_date": ISO8601DateFormatter().string(from: workoutRecord.startDate),  // Format startDate
            "end_date": ISO8601DateFormatter().string(from: workoutRecord.endDate),      // Format endDate
            "duration": workoutRecord.duration,
            "calories": workoutRecord.calories,
            "distance": workoutRecord.distance,
            "elevation_gain": workoutRecord.elevationGain
        ]
        
        let filteredWorkoutData = workoutData.compactMapValues { $0 }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: filteredWorkoutData, options: .fragmentsAllowed)

        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending workout data: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("Server returned an error: \(httpResponse.statusCode)")
            } else {
                print("Workout data sent successfully.")
            }
        }.resume()
    }

    
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
