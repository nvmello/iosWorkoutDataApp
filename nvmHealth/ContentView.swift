import SwiftUI
import HealthKit

struct ContentView: View {
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
            self.requestAuthorization()
        }
    }

    private func requestAuthorization() {
        guard let healthStore = self.healthStore else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }

        let readTypes: Set<HKObjectType> = [
//            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if success {
                print("Authorization succeeded.")
                self.startWorkoutObserver()
            } else if let error = error {
                print("Authorization failed: \(error.localizedDescription)")
            }
        }
    }


    private func fetchMostRecentWorkout() {
            guard let healthStore = self.healthStore else { return }

            let workoutType = HKObjectType.workoutType()
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
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
    
    private func startWorkoutObserver() {
            guard let healthStore = self.healthStore else { return }
            let workoutType = HKObjectType.workoutType()

            let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { query, completionHandler, error in
                if let error = error {
                    print("Observer query failed: \(error.localizedDescription)")
                    return
                }
                print("New workout detected.")
                self.fetchMostRecentWorkout()  // Fetch new workout data
                completionHandler()  // Call completion to allow HealthKit to manage resources
            }

            healthStore.execute(query)
        }

    
    private func processWorkout(_ workout: HKWorkout) {
        let workoutType = workout.workoutActivityType.name
        let duration = workout.duration / 60  // Convert to minutes
        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        let endDate  = workout.endDate;
        print("\nworkoutType")
        print(workoutType)
        print("\nduration")
        print(duration)
        print("\ncalories")
        print(calories)
        print("\nendDate")
        print(endDate)
        print("\nworkoutActivityType")
        print(workout.workoutActivityType)
        print("\ndescription")
        print(workout.description)
        print("\nmetadata")
        print(workout.metadata as Any)
        print("\nobservation info")
        print(workout.observationInfo as Any)

        self.recentWorkout = "\(workoutType), \(String(format: "%.1f", duration)) mins, \(String(format: "%.0f", calories)) kcal"

        // Send data to your website here
        sendWorkoutDataToWebsite(type: workoutType, duration: duration, calories: calories)
    }

    private func sendWorkoutDataToWebsite(type: String, duration: Double, calories: Double) {
        guard let url = URL(string: "http://192.168.12.88:3000/api/workout") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let workoutData: [String: Any] = [
                "type": type,
                "duration": duration,
                "calories": calories
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: workoutData, options: .fragmentsAllowed)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending workout data: \(error.localizedDescription)")
                } else {
                    print("Workout data sent successfully.")
                }
            }.resume()
        }
}

extension HKWorkoutActivityType {
    var name: String {
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
