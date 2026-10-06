// Models/AICoachEngine.swift
import Foundation

struct AICoachMessage: Identifiable, Equatable {
    let id: UUID
    let sender: MessageSender
    let text: String
    let timestamp: Date
    let category: MessageCategory?
    let suggestions: [String]

    init(
        id: UUID = UUID(),
        sender: MessageSender,
        text: String,
        timestamp: Date = Date(),
        category: MessageCategory? = nil,
        suggestions: [String] = []
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.category = category
        self.suggestions = suggestions
    }

    enum MessageSender: Equatable {
        case user
        case coach
    }

    enum MessageCategory: String {
        case workout = "Workout & Training"
        case nutrition = "Food & Macros"
        case running = "Running & Cardio"
        case recovery = "Recovery & Sleep"
        case general = "General Fitness"
    }
}

@MainActor
final class AICoachEngine: ObservableObject {
    @Published var messages: [AICoachMessage] = []
    @Published var isThinking: Bool = false

    static let defaultPrompts: [(title: String, prompt: String, icon: String)] = [
        ("High-protein post-workout meal", "What is a quick 40g+ protein post-workout meal I can make?", "fork.knife"),
        ("Chest & Tricep Hypertrophy", "Give me an effective 45-minute Chest and Tricep workout with sets and reps.", "dumbbell.fill"),
        ("How to improve 5K pace", "What training split or interval workouts will help lower my 5K running pace?", "figure.run"),
        ("Pre-workout snack ideas", "What are optimal pre-workout carbs to eat 30-45 minutes before lifting?", "bolt.fill"),
        ("Fix sore legs & recovery", "What are the best recovery methods for severe leg day DOMS soreness?", "heart.fill")
    ]

    init() {
        // Welcome greeting from Solxce AI Coach
        messages = [
            AICoachMessage(
                sender: .coach,
                text: "Hey Athlete! 👋 I'm your **Solxce AI Coach**.\n\nAsk me anything about:\n• Workout routines, exercise form & split design\n• High-protein meals, macro calculations & nutrition\n• Running pace, distance progression & endurance\n• Muscle recovery, hydration & supplement guidance\n\nWhat can I help you crush today?",
                category: .general,
                suggestions: [
                    "High-protein post-workout meal",
                    "Chest & Tricep Hypertrophy",
                    "How to improve 5K pace",
                    "Pre-workout snack ideas"
                ]
            )
        ]
    }

    func sendMessage(_ userText: String) async {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Append user query
        let userMessage = AICoachMessage(sender: .user, text: trimmed)
        messages.append(userMessage)
        isThinking = true

        // Simulate intelligent response delay
        try? await Task.sleep(nanoseconds: 650_000_000)

        let coachResponse = generateResponse(for: trimmed)
        messages.append(coachResponse)
        isThinking = false
    }

    func clearChat() {
        messages = [
            AICoachMessage(
                sender: .coach,
                text: "Chat cleared! What fitness or nutrition topic would you like to explore next?",
                category: .general,
                suggestions: [
                    "High-protein post-workout meal",
                    "Chest & Tricep Hypertrophy",
                    "How to improve 5K pace"
                ]
            )
        ]
    }

    // MARK: - Smart Response Synthesis
    private func generateResponse(for query: String) -> AICoachMessage {
        let q = query.lowercased()

        // 1. Food / Nutrition / Protein / Meals / Macros
        if q.contains("food") || q.contains("meal") || q.contains("protein") || q.contains("macro") || q.contains("carb") || q.contains("eat") || q.contains("diet") || q.contains("breakfast") || q.contains("lunch") || q.contains("dinner") || q.contains("snack") || q.contains("chicken") || q.contains("calorie") {
            return handleNutritionQuery(q)
        }

        // 2. Running / Pace / 5K / Marathon / Cardio / Treadmill
        if q.contains("run") || q.contains("pace") || q.contains("mile") || q.contains("5k") || q.contains("10k") || q.contains("cardio") || q.contains("jog") || q.contains("speed") || q.contains("interval") {
            return handleRunningQuery(q)
        }

        // 3. Workouts / Sets / Muscle Groups / Splits / Exercises
        if q.contains("workout") || q.contains("chest") || q.contains("back") || q.contains("leg") || q.contains("arm") || q.contains("shoulder") || q.contains("bench") || q.contains("squat") || q.contains("deadlift") || q.contains("hypertrophy") || q.contains("split") || q.contains("push") || q.contains("pull") || q.contains("rep") || q.contains("bicep") || q.contains("tricep") {
            return handleWorkoutQuery(q)
        }

        // 4. Recovery / Sleep / Sore / DOMS / Water / Creatine
        if q.contains("sore") || q.contains("recovery") || q.contains("sleep") || q.contains("doms") || q.contains("stretch") || q.contains("creatine") || q.contains("supplement") || q.contains("water") || q.contains("hydrate") {
            return handleRecoveryQuery(q)
        }

        // 5. General Fitness / Fat loss / Bulking / Motivation
        return handleGeneralQuery(q)
    }

    // MARK: - Specialized Category Generators
    private func handleNutritionQuery(_ q: String) -> AICoachMessage {
        if q.contains("post") || q.contains("after workout") {
            return AICoachMessage(
                sender: .coach,
                text: "⚡ **Optimal Post-Workout Nutrition (30–60 Min Window)**\n\nYour muscles need fast-digesting protein to kickstart protein synthesis and carbohydrates to restore depleted glycogen:\n\n1. **Golden Ratio Power Bowl**:\n   • 7 oz Grilled Chicken Breast (46g Protein)\n   • 1.5 cups Jasmine White Rice (65g Carbs)\n   • 1/2 Avocado (10g Healthy Fats)\n   *Total: ~580 kcal | 48g P / 68g C / 14g F*\n\n2. **Express Shake & Oats**:\n   • 1.5 scoops Whey Isolate (38g Protein)\n   • 1 medium Banana + 1/2 cup blended oats (45g Carbs)\n   • 1 tbsp Peanut butter\n   *Total: ~450 kcal | 42g P / 52g C / 10g F*\n\n💡 *Tip: Log these in your Today tab under Food Log to keep your macro progress rings synchronized!*",
                category: .nutrition,
                suggestions: ["What about pre-workout snacks?", "How much daily protein do I need?", "Healthy low-calorie high-protein snacks"]
            )
        } else if q.contains("snack") || q.contains("quick") {
            return AICoachMessage(
                sender: .coach,
                text: "🍎 **Quick High-Protein Snacks (Under 5 Mins Prep)**\n\n• **Greek Yogurt Parfait**: 1 cup Non-Fat Greek Yogurt + 1 scoop vanilla whey + berries (*38g Protein, 220 kcal*)\n• **Cottage Cheese & Honey**: 1 cup 2% cottage cheese with sliced apple (*28g Protein, 210 kcal*)\n• **Turkey & Rice Cakes**: 4 slices lean deli turkey breast over 2 salted rice cakes (*24g Protein, 160 kcal*)\n• **Edamame**: 1.5 cups steamed edamame with sea salt (*26g Protein, 240 kcal*)\n\nThese will keep you satiated without spiking unnecessary saturated fats.",
                category: .nutrition,
                suggestions: ["Suggest dinner ideas for fat loss", "Best carbs for lifting", "How to hit 180g protein easily"]
            )
        } else {
            return AICoachMessage(
                sender: .coach,
                text: "🥗 **Nutrition & Macro Blueprint**\n\nFor body composition optimization:\n• **Protein Target**: Aim for `0.8g – 1.0g` of protein per pound of target body weight daily (e.g. 170 lbs = 140–170g protein).\n• **Carbohydrate Timing**: Concentrate ~60% of daily complex carbs around your training window for maximum glycogen power.\n• **Essential Fats**: Keep fats at ~20–25% of total caloric intake to support hormonal balance.\n\nWould you like a tailored daily meal plan or a specific recipe breakdown?",
                category: .nutrition,
                suggestions: ["High-protein post-workout meal", "Sample 2,400 kcal day plan", "Pre-workout meal timing"]
            )
        }
    }

    private func handleRunningQuery(_ q: String) -> AICoachMessage {
        return AICoachMessage(
            sender: .coach,
            text: "🏃 **Pace Acceleration & Endurance Strategy**\n\nTo shave time off your pace without burning out:\n\n1. **The 80/20 Rule**:\n   • 80% of your weekly mileage should be at an **Easy Conversational Zone 2 Pace** (where you can speak in full sentences).\n   • 20% dedicated to high-intensity threshold/interval work.\n\n2. **Speed Interval Workout (1x/week)**:\n   • 10 min easy warm-up jog\n   • 6 x 400m repeats at 30 sec faster than your target 5K pace (with 90 sec walking rest between)\n   • 5 min cool-down\n\n3. **Cadence Focus**:\n   • Aim for 170–180 strides/min to minimize ground contact time and reduce knee joint impact.\n\n💡 *Tip: Fire up Solxce's **Run Log** and tap START RUN to monitor your live GPS pace and per-mile split cadence in real-time!*",
            category: .running,
            suggestions: ["How to prepare for a 10K", "Best shoes for daily running", "How to avoid shin splints"]
        )
    }

    private func handleWorkoutQuery(_ q: String) -> AICoachMessage {
        if q.contains("chest") || q.contains("push") {
            return AICoachMessage(
                sender: .coach,
                text: "💥 **Hypertrophy Chest & Tricep Session**\n\n*Rest 90-120s between compound lifts, 60s for isolations:*\n\n1. **Barbell Flat Bench Press** — 4 Sets x 6-8 Reps (Heavy, explosive press, controlled 3s eccentric)\n2. **Incline Dumbbell Press (30° angle)** — 3 Sets x 8-10 Reps (Deep chest stretch)\n3. **Cable Chest Flyes / Pec Deck** — 3 Sets x 12-15 Reps (Squeeze at peak contraction for 1s)\n4. **Weighted Dips** — 3 Sets x 8-10 Reps (Slight forward lean for lower pec recruitment)\n5. **Cable Tricep Rope Pushdowns** — 4 Sets x 12-15 Reps (Flare ropes apart at bottom)\n6. **Overhead Dumbbell Extension** — 3 Sets x 10-12 Reps (Long head tricep stretch)\n\nTrack every set in the Solxce **Workout Logger** to progressive overload next week!",
                category: .workout,
                suggestions: ["Back & Bicep routine", "Legs & Core workout", "How to increase Bench Press 1RM"]
            )
        } else if q.contains("leg") || q.contains("squat") {
            return AICoachMessage(
                sender: .coach,
                text: "🍗 **Quad & Hamstring Power Blueprint**\n\n1. **Barbell Back Squats** — 4 Sets x 6-8 Reps (Below parallel, core braced)\n2. **Romanian Deadlifts (RDLs)** — 4 Sets x 8-10 Reps (Hinge hips back, feel hamstring stretch)\n3. **Bulgarian Split Squats** — 3 Sets x 10-12 Reps/leg (Brutal quad & glute hypertrophy)\n4. **Seated or Lying Leg Curls** — 3 Sets x 12-15 Reps (Controlled tempo)\n5. **Standing Calf Raises** — 4 Sets x 15-20 Reps (2-second pause at top stretch)\n\nDon't skip post-leg hydration and 40g+ protein!",
                category: .workout,
                suggestions: ["How to fix squat knee cave", "Shoulder & Arm split", "Upper / Lower split plan"]
            )
        } else {
            return AICoachMessage(
                sender: .coach,
                text: "🏋️ **Hypertrophy Training Principles**\n\nTo maximize muscle growth and strength progression:\n\n• **Proximity to Failure (RIR)**: Take working sets to 1–2 Reps in Reserve (RIR). The last 3 reps produce ~85% of hypertrophy stimulus.\n• **Weekly Volume**: Aim for 12–18 direct working sets per muscle group across the week.\n• **Progressive Overload**: Every week, aim to add either 1 rep or +2.5–5 lbs to your main compound lifts.\n\nCheck your **Planner** tab to assign your weekly muscle splits and track scheduled days!",
                category: .workout,
                suggestions: ["Chest & Tricep routine", "Back & Bicep routine", "Full body 3-day split"]
            )
        }
    }

    private func handleRecoveryQuery(_ q: String) -> AICoachMessage {
        return AICoachMessage(
            sender: .coach,
            text: "🌙 **Muscle Recovery & DOMS Protocol**\n\nMuscle tissue doesn't grow in the gym; it grows during recovery:\n\n1. **Sleep Architecture**: 7.5 to 9 hours of uninterrupted sleep drives peak Growth Hormone (GH) secretion.\n2. **Hydration & Electrolytes**: Drink `half your bodyweight (lbs) in ounces of water` daily. Add a pinch of sea salt and potassium after sweaty sessions.\n3. **Active Recovery**: A 20-minute light jog (Zone 1) or cycling flush promotes blood flow and clears metabolic waste faster than sitting stationary.\n4. **Creatine Monohydrate**: 5g daily consistently improves muscular cell hydration, power output, and recovery between sets.\n\nListen to your body — if joint fatigue is high, mark today as a Rest Day in your Planner!",
            category: .recovery,
            suggestions: ["Benefits of Creatine Monohydrate", "How much water should I drink?", "Foam rolling mobility guide"]
        )
    }

    private func handleGeneralQuery(_ q: String) -> AICoachMessage {
        return AICoachMessage(
            sender: .coach,
            text: "🔥 **Solxce Athletic Advice**\n\nWhether your goal is building lean muscle, dropping body fat, or crushing endurance PRs, consistency and progressive overload win every time:\n\n• **Training**: Follow your structured split in the **Planner** tab.\n• **Fueling**: Hit your protein & calorie targets daily in the **Today** rings.\n• **Cardio**: Track your pace and miles with the GPS **Run Log**.\n• **Community**: Share your milestones and get inspired in the **Feed**.\n\nAsk me any specific question about exercises, nutrition facts, meal ideas, or running techniques!",
            category: .general,
            suggestions: [
                "High-protein post-workout meal",
                "Chest & Tricep Hypertrophy",
                "How to improve 5K pace",
                "Calculate daily macros"
            ]
        )
    }
}
