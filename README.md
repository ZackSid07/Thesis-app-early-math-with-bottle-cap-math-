# MathBuddy: Bottle Cap Math

MathBuddy is an educational Flutter application designed for children. It uses on-device artificial intelligence (YOLO) to detect physical bottle caps representing numbers and operators, enabling an interactive and tactile learning experience.

---

## Project History & Technical Milestones

This section serves as a technical log for future AI agents and developers.

### 1. Build & Core Setup
*   **Android Stabilization**: Resolved critical build failures related to "Namespace not specified" by configuring the `build.gradle.kts` with a dynamic namespace injection script.
*   **Dependency Management**: Established a stable core using `camera`, `flutter_vision` (YOLO integration), `flutter_tts` (Speech), and `image` (Pre-processing).

### 2. Architectural Pivot: Live -> Snap
*   **Problem**: Initial real-time video stream processing caused significant main-thread lag (dropping frames) and low detection accuracy due to motion blur and variable aspect ratios.
*   **Solution**: Moved to a **"Snap & Analyze"** architecture. The app now captures a high-resolution image when the user clicks "Check," ensuring the AI works with the highest quality data possible.

### 3. Inference & Detection Optimization
*   **Aspect Ratio Correction**: Implemented a **Center-Square Cropping** algorithm using the `image` package. Conventional wide-angle camera captures were being distroted when scaled to the 640x640 YOLO input. Cropping a square preserves the circular shape of the caps, significantly improving classification accuracy.
*   **Robust Deduplication**: Developed a dynamic deduplication algorithm that uses box-width percentages to remove "ghost" detections/overlaps commonly seen in high-resolution inferences.
*   **Sorting Logic**: Standardized Left-to-Right detection ordering based on the X-axis coordinate of detected bounding boxes within the square-cropped frame.
*   **Sensitivity Tuning**: Tuned YOLO `confThreshold` and `iouThreshold` to balance detection sensitivity with false-positive rejection.

### 4. Equation Logic
*   **Parser**: Implemented a multi-step parser that handles numbers, basic operators (+, -, *, /), and the equals sign.
*   **Validation**: The app validates the entire sequence against an expected "answer cap" detected at the end of the equation.

---

## Recently Implemented Features

### 1. High-Fidelity Child-Friendly UI
*   **HomeScreen Overhaul**: Completely redesigned with a soft cream dotted background, a "Math Buddy" header with a robot mascot, and 3D squishy `AnimatedPuffyButton`s for navigation.
*   **Interactive Equation Card**: Dynamically renders the current level's equation using visual `BottleCapWidget`s, replacing the answer cap with a mystery sparkled cap.

### 2. Practice Mode ("Sharpen Skills")
*   **Sandbox Play**: Allows children to scan any valid math equation without being restricted to completing a specific level.
*   **AI-Driven Feedback**: Incorrect attempts in Practice Mode trigger the `GeminiService` to explain the specific mistake conceptually via the `HintScreen`.

### 3. Audio & Accessibility (Text-to-Speech)
*   **"Hear it!" Button**: Integrated `flutter_tts` into the HomeScreen. Tapping the volume icon reads the current equation aloud (e.g., "One plus two equals three").
*   **Text Translation**: Added visual helper text below equations that translates digits and symbols into full readable words.

### 4. Settings & Parental Controls
*   **Fully Functional SettingsScreen**: Built a polished settings panel to toggle "Sound & Music" and switch "Voice Instructions" language options. State is managed by a new `SettingsProvider`.
*   **Parental Gate**: Added a mathematical verification dialog (e.g., "What is 12 x 4?") to the "Reset All Progress" button to prevent accidental data loss by children.

### 5. Curriculum Auto-Save
*   **Persistent Progress**: Overhauled the `CourseProvider` to automatically save the child's `highestUnlockedLevelId` into local storage (`SharedPreferences`) the moment a level is completed.
*   **Seamless Resumption**: App initialization invokes `loadProgress()` to instantly rebuild the course progression map precisely where the user left off.

---

## Tech Stack
*   **Framework**: Flutter
*   **AI**: TensorFlow Lite (YOLOv5/v8 model)
*   **Utilities**: Google Fonts (Nunito), Text-to-Speech.

## Setup
1.  Add `assets/models/best_float32.tflite` and `labels.txt`.
2.  Run `flutter pub get`.
3.  Deploy to a physical device (required for camera/TFLite performance).

