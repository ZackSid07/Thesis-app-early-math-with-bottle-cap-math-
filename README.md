# Bottle Cap Math

An educational offline app for children that uses the camera to detect physical bottle caps and solves math equations in real-time.

## Setup Instructions

1.  **Install Flutter**: Ensure Flutter is installed and in your PATH.
    *   If you haven't already initialized the project structure (android, ios, etc.), run:
        ```bash
        flutter create . --project-name=math_buddy
        ```
        *Note: Choose "No" if it asks to overwrite `lib/main.dart` or other files we created, OR let it overwrite and then restore them. Better yet, run it in a separate folder and copy the `android`, `ios`, `web`, `macos`, `linux`, `windows` folders here.*

2.  **Add Assets**:
    *   Place your `best.tflite` model file in `assets/models/`.
    *   Place your `labels.txt` file in `assets/models/`.

3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

4.  **Run the App**:
    *   Connect a physical device.
    *   Run:
        ```bash
        flutter run
        ```

## Features

*   **Real-time Object Detection**: Uses YOLO (TensorFlow Lite) to detect numbers and operators.
*   **Equation Solving**: Automatically solves the detected equation.
*   **Interactive Feedback**: TTS and visual feedback for correct/incorrect answers.
*   **Ghost Overlay**: Visual guide to help align bottle caps.

## Structure

*   `lib/services/yolo_service.dart`: Handles loading the model and running inference.
*   `lib/screens/camera_screen.dart`: The main screen with camera, overlay, and logic.
*   `lib/main.dart`: App entry point and theme configuration.
