//
//  HealthManager.swift
//  BeActive
//
//  Created by Kasin Thappawan on 29/5/2567 BE.
//

import Foundation
import HealthKit
//ส่วนนี้เป็นส่วนที่สำคัญที่สุด
extension Date {
    // น่าจะเป็นการกำหนดวันที่ในการออกกำลังกาย
    static var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }
    // น่าจะเป็นตารางการออกกำลังกายในแต่ละวีค
    static var startOfWeek: Date {
        let calenda = Calendar.current
        var component = calenda.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        component.weekday = 2
        
        return calenda.date(from: component)!
    }
}
// เลขทศนิยม
extension Double {
    func formattedString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter.string(from: NSNumber(value: self))!
    }
}


class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var activities: [String : Activity] = [:] // ประกาศ activities ให้สามารถใช้ได้ทุกส่วนการทำงาน
    @Published var MockActivities: [String : Activity] = [
        "todaySteps" : Activity(id: 0, title: "Today steps", subtitle: "Goal 10,000", image: "figure.walk", tintColor: .green, amount: "12,123"),
        "todayCalories" : Activity(id: 1, title: "Today Calories", subtitle: "Goal 900", image: "flame", tintColor: .red, amount: "1,241")
    ] // ประกาศ MockActivities ให้สามารถใช้ได้ทุกส่วนการทำงาน
    
    init() {
        let steps = HKQuantityType(.stepCount)// .stepCount คือ ค่าที่ใช้ใน Apple wacth
        let calories = HKQuantityType(.activeEnergyBurned) // activeEnergyBurned คือ ค่าที่ใช้ใน Apple wacth
        let workout = HKObjectType.workoutType()
        let healthTypes: Set = [steps, calories, workout]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
                fetchTodaySteps()
                fetchTodayCalories()
                fetchCurrentWeekWorkoutStats()
            } catch {
                print("Error requesting health data authorization")
            }
        }
    }
    
    
    
    // ฟังก์ชั่นวัดจำนวนการก้าวเดินในแต่ละวัน
    func fetchTodaySteps() {
        let steps = HKQuantityType(.stepCount)
        //น่าจะเป็นส่วนเชื่อมต่อระหว่างแอป กับ Apple watch
        let calories = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery .predicateForSamples(withStart: .startOfDay, end: Date())
        //อันนี้น่าจะเป็นส่วนในการแสดงค่าข้อมูลมั้ง
        let query = HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: predicate) { _, result, error in guard let quantity = result?.sumQuantity(), error == nil else {
            print("error fetching todays step data")
            return
        }
            
            let stepCount = quantity.doubleValue (for: .count())
            let activity = Activity(id: 0, title: "Today steps", subtitle: "Goal 10,000", image: "figure.walk", tintColor: .green, amount: stepCount.formattedString())
            
            DispatchQueue.main.async {
                self.activities["todaySteps"] = activity
            }
        }
        healthStore.execute(query)
    }
    
     //ฟังชั่นวัดแคลลอรี่ที่เผาผลาญในแต่ละวัน
    func fetchTodayCalories() {
        let calories = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: calories, quantitySamplePredicate: predicate) { _, result, error in guard let quantity = result?.sumQuantity(), error == nil else {
            print("error fetching todays Calories data")
            return
        }
            
            let CaloriesBurned = quantity.doubleValue (for: .kilocalorie())
            let activity = Activity(id: 1, title: "Today Calories", subtitle: "Goal 900", image: "flame", tintColor: .red, amount: CaloriesBurned.formattedString())
            
            DispatchQueue.main.async {
                self.activities["todayCalories"] = activity
            }
        }
        healthStore.execute(query)
    }
    
    //ฟังชั่นวัดการออกกำลังกายในแต่ละสัปดาห์
    func fetchCurrentWeekStrengthStats() {
        let workout = HKSampleType.workoutType()
        let timepredicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timepredicate, workoutPredicate])
        let query = HKSampleQuery (sampleType: workout, predicate: predicate,limit: 20,sortDescriptors: nil) {_, sample, error in guard let workouts = sample as? [HKWorkout], error == nil else {
                print ("errorfetching todays running data")
                return
            }
            var count: Int = 0
            for workout in workouts {
                let duration = Int(workout.duration)/60
                count += duration
            }
            let activity = Activity(id: 3, title: "Weight Lifting", subtitle: "This week", image: "dumbbell", tintColor: .brown, amount: "\(count) minutes")
            
            DispatchQueue.main.async {
                self.activities["weekStrength"] = activity
            }
        }
        healthStore.execute(query)
    }
    // ฟังชั่นวัดการออกกำลังกายทั้งหมด
    func fetchCurrentWeekWorkoutStats() {
        let workout = HKSampleType.workoutType()
        let timepredicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKSampleQuery (sampleType: workout, predicate: timepredicate,limit: HKObjectQueryNoLimit,sortDescriptors: nil) {_, sample, error in guard let workouts = sample as? [HKWorkout], error == nil else {
                print ("errorfetching todays running data")
                return
            }
            var runningCount: Int = 0
            var traditionalCount: Int = 0
            var soccerCount: Int = 0
            var basketballCount: Int = 0
            for workout in workouts {
                if workout.workoutActivityType == .running {
                    let duration = Int(workout.duration)/60
                    runningCount += duration
                } else if workout.workoutActivityType == .traditionalStrengthTraining {
                    let duration = Int(workout.duration)/60
                    traditionalCount += duration
                } else if workout.workoutActivityType == .soccer {
                    let duration = Int(workout.duration)/60
                    soccerCount += duration
                } else if workout.workoutActivityType == .basketball {
                    let duration = Int(workout.duration)/60
                    basketballCount += duration
                }
            }
            let Runningactivity = Activity(id: 2, title: "Running", subtitle: "This week", image: "figure.run", tintColor: .orange, amount: "\(runningCount) minutes")
            let Traditionlactivity = Activity(id: 3, title: "Weight", subtitle: "This week", image: "figure.strengthtraining.traditional", tintColor: .black, amount: "\(traditionalCount) minutes")
            let Socceractivity = Activity(id: 4, title: "Soccer", subtitle: "This week", image: "figure.soccer", tintColor: .pink, amount: "\(soccerCount) minutes")
            let Basketballactivity = Activity(id: 5, title: "Basketball", subtitle: "This week", image: "figure.basketball", tintColor: .indigo, amount: "\(basketballCount) minutes")
            
            DispatchQueue.main.async {
                self.activities["weekRunning"] = Runningactivity
                self.activities["weekStrength"] = Traditionlactivity
                self.activities["weekSoccer"] = Socceractivity
                self.activities["weekBasketball "] = Basketballactivity
            }
        }
        healthStore.execute(query)
    }
}



