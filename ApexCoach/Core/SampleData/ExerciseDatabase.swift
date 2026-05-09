import Foundation

struct ExerciseTemplate: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var equipment: [EquipmentType]
    var instructions: [String]
    var tips: [String]
    var safetyNotes: [String]
}

enum ExerciseDatabase {
    static let all: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Goblet Squat",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.core, .hamstrings],
            equipment: [.dumbbells, .fullGym],
            instructions: ["Hold the weight close to your chest.", "Sit between your hips with your chest tall.", "Drive through the mid-foot to stand."],
            tips: ["Keep the ribs stacked over the pelvis.", "Use a controlled lower and crisp stand."],
            safetyNotes: ["Stop the set if knee or back pain changes your movement."]
        ),
        ExerciseTemplate(
            name: "Dumbbell Bench Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: [.dumbbells, .fullGym],
            instructions: ["Set shoulder blades down and back.", "Lower dumbbells with elbows about 45 degrees from your torso.", "Press until arms are long without shrugging."],
            tips: ["Think smooth pressure through the handles.", "Pause briefly at the bottom for control."],
            safetyNotes: ["Avoid bouncing or forcing range if shoulders feel pinchy."]
        ),
        ExerciseTemplate(
            name: "Push-Up",
            primaryMuscles: [.chest, .triceps],
            secondaryMuscles: [.shoulders, .core],
            equipment: [.bodyweight, .fullGym],
            instructions: ["Set hands just outside shoulder width.", "Brace as if holding a plank.", "Lower as one piece and press the floor away."],
            tips: ["Elevate hands to make reps cleaner.", "Lock in the core before every rep."],
            safetyNotes: ["Keep wrists neutral and stop before shoulder discomfort."]
        ),
        ExerciseTemplate(
            name: "Barbell Back Squat",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.core, .hamstrings],
            equipment: [.barbells, .fullGym],
            instructions: ["Set the bar securely on upper back.", "Brace before each rep.", "Descend under control and stand with speed."],
            tips: ["Treat each rep like a single.", "Keep pressure through the whole foot."],
            safetyNotes: ["Use safeties and avoid max attempts without a spotter."]
        ),
        ExerciseTemplate(
            name: "Romanian Deadlift",
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.back, .core],
            equipment: [.barbells, .dumbbells, .fullGym],
            instructions: ["Start tall with soft knees.", "Push hips back until hamstrings load.", "Stand by driving hips through."],
            tips: ["Keep weights close to the legs.", "Stop the descent before the back rounds."],
            safetyNotes: ["Reduce range if you cannot keep a neutral spine."]
        ),
        ExerciseTemplate(
            name: "Lat Pulldown",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .shoulders],
            equipment: [.machines, .fullGym],
            instructions: ["Anchor thighs under the pad.", "Pull elbows toward your ribs.", "Return slowly until arms are long."],
            tips: ["Lead with elbows, not hands.", "Keep the torso quiet."],
            safetyNotes: ["Do not pull behind the neck."]
        ),
        ExerciseTemplate(
            name: "One-Arm Dumbbell Row",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .core],
            equipment: [.dumbbells, .fullGym],
            instructions: ["Support your torso with a bench or staggered stance.", "Pull the dumbbell toward your hip.", "Lower until the shoulder blade reaches forward."],
            tips: ["Pause at the top without twisting.", "Keep the neck relaxed."],
            safetyNotes: ["Avoid yanking the weight from the floor."]
        ),
        ExerciseTemplate(
            name: "Seated Cable Row",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .shoulders],
            equipment: [.machines, .fullGym],
            instructions: ["Sit tall with ribs down.", "Pull handles toward lower ribs.", "Return with control."],
            tips: ["Let shoulder blades move naturally.", "Do not lean back to finish reps."],
            safetyNotes: ["Keep the low back neutral."]
        ),
        ExerciseTemplate(
            name: "Dumbbell Shoulder Press",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps, .core],
            equipment: [.dumbbells, .fullGym],
            instructions: ["Start with dumbbells near shoulders.", "Brace and press overhead.", "Lower slowly to the start."],
            tips: ["Keep biceps near ears at the top.", "Use a seated setup if you need more control."],
            safetyNotes: ["Avoid arching the lower back to finish reps."]
        ),
        ExerciseTemplate(
            name: "Lateral Raise",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.core],
            equipment: [.dumbbells, .resistanceBands, .fullGym],
            instructions: ["Hold light weights at your sides.", "Raise arms to shoulder height.", "Lower slowly without swinging."],
            tips: ["Lead with elbows.", "Keep traps quiet and neck long."],
            safetyNotes: ["Use a pain-free range only."]
        ),
        ExerciseTemplate(
            name: "Machine Chest Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: [.machines, .fullGym],
            instructions: ["Set handles at mid-chest.", "Press forward with shoulders down.", "Return until chest is gently stretched."],
            tips: ["Control the negative.", "Keep wrists stacked over elbows."],
            safetyNotes: ["Do not force the seat position if shoulders feel compressed."]
        ),
        ExerciseTemplate(
            name: "Walking Lunge",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipment: [.bodyweight, .dumbbells, .fullGym],
            instructions: ["Step forward into a long stance.", "Lower until both knees bend comfortably.", "Drive through the front foot into the next step."],
            tips: ["Keep steps quiet and balanced.", "Shorten stride if hips feel unstable."],
            safetyNotes: ["Avoid collapsing the front knee inward."]
        ),
        ExerciseTemplate(
            name: "Hip Thrust",
            primaryMuscles: [.glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipment: [.barbells, .machines, .fullGym],
            instructions: ["Set upper back on a bench.", "Tuck ribs down and brace.", "Drive hips up until glutes lock out."],
            tips: ["Pause for one beat at the top.", "Keep chin slightly tucked."],
            safetyNotes: ["Avoid overextending the lower back."]
        ),
        ExerciseTemplate(
            name: "Band Pull-Apart",
            primaryMuscles: [.back, .shoulders],
            secondaryMuscles: [.triceps],
            equipment: [.resistanceBands, .fullGym],
            instructions: ["Hold a band at shoulder height.", "Pull hands apart until the band reaches the chest.", "Return slowly with tension."],
            tips: ["Keep ribs down.", "Use a lighter band for clean control."],
            safetyNotes: ["Do not snap the band back."]
        ),
        ExerciseTemplate(
            name: "Plank",
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders, .glutes],
            equipment: [.bodyweight, .fullGym],
            instructions: ["Set elbows under shoulders.", "Squeeze glutes lightly.", "Hold a straight line from head to heels."],
            tips: ["Exhale slowly to keep tension.", "Stop before form breaks."],
            safetyNotes: ["Drop to knees if the low back takes over."]
        ),
        ExerciseTemplate(
            name: "Dead Bug",
            primaryMuscles: [.core],
            secondaryMuscles: [.quads],
            equipment: [.bodyweight, .fullGym],
            instructions: ["Lie on your back with knees over hips.", "Press low back gently toward the floor.", "Extend opposite arm and leg with control."],
            tips: ["Move slower than you think.", "Reset the brace every rep."],
            safetyNotes: ["Shorten range if the back arches."]
        ),
        ExerciseTemplate(
            name: "Battle Rope Intervals",
            primaryMuscles: [.shoulders, .core],
            secondaryMuscles: [.back, .glutes],
            equipment: [.fullGym],
            instructions: ["Set an athletic stance.", "Create fast alternating waves.", "Stay tall through the torso."],
            tips: ["Make the waves crisp, not huge.", "Breathe continuously."],
            safetyNotes: ["Stop if shoulder rhythm becomes painful."]
        ),
        ExerciseTemplate(
            name: "Mountain Climber",
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders, .quads],
            equipment: [.bodyweight, .fullGym],
            instructions: ["Start in a tall plank.", "Drive one knee toward your chest.", "Switch legs with steady rhythm."],
            tips: ["Keep hips level.", "Choose speed only after control is solid."],
            safetyNotes: ["Elevate hands if wrists or hips feel strained."]
        ),
        ExerciseTemplate(
            name: "Calf Raise",
            primaryMuscles: [.calves],
            secondaryMuscles: [.quads],
            equipment: [.bodyweight, .dumbbells, .machines, .fullGym],
            instructions: ["Stand tall with feet hip width.", "Rise onto the balls of your feet.", "Lower slowly to a full stretch."],
            tips: ["Pause at the top and bottom.", "Use a wall for balance if needed."],
            safetyNotes: ["Avoid rolling ankles outward."]
        ),
        ExerciseTemplate(
            name: "Assisted Pull-Up",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .core],
            equipment: [.machines, .resistanceBands, .fullGym],
            instructions: ["Set assistance so reps are clean.", "Pull chest toward the bar.", "Lower until elbows are long."],
            tips: ["Keep shoulders away from ears.", "Own the last two inches of the descent."],
            safetyNotes: ["Avoid swinging into the rep."]
        )
    ]
}
