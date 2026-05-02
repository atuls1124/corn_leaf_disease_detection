# Maize Leaf Disease Detection App

A Flutter-based Android application that uses a deep learning model to detect diseases in maize (corn) leaves from images.

## Project Overview

This app provides disease detection for maize crops using a trained CNN model. It can identify 7 different conditions:
- Bacterial Leaf Streak
- Common Rust
- Gray Leaf Spot
- Healthy
- Maize Chlorotic Mottle Virus
- Maize Streak Virus
- Northern Leaf Blight

## Features

- **Image Input**: Capture images using camera or select from gallery
- **Multi-Image Support**: Select multiple images for batch processing
- **Disease Prediction**: Run inference using TensorFlow Lite model
- **Confidence Display**: Show prediction confidence percentage
- **Grad-CAM Visualization**: Display AI attention heatmap showing where the model focuses
- **Modern UI**: Clean, intuitive interface with loading indicators
- **Error Handling**: Graceful handling of invalid images and model failures

## Project Structure

```
maize_disease_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/
│   │   └── disease_model.dart  # TensorFlow Lite model handler
│   ├── screens/
│   │   ├── splash_screen.dart # Splash/loading screen
│   │   ├── home_screen.dart   # Main upload screen
│   │   └── result_screen.dart # Prediction results display
│   ├── utils/
│   │   ├── app_theme.dart     # App theme and styling
│   │   └── grad_cam_service.dart # Heatmap visualization
│   └── widgets/               # Reusable widgets
├── assets/
│   └── model/
│       └── maize_disease_model.tflite  # Converted ML model
├── android/                   # Android configuration
└── pubspec.yaml              # Flutter dependencies
```

## Prerequisites

1. **Flutter SDK**: Version 3.x or higher
2. **Android SDK**: API level 21 or higher
3. **Dart**: Version 3.x or higher

## Installation

### 1. Clone or Download the Project

```bash
cd maize_disease_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Build Debug APK

```bash
flutter build apk --debug
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-debug.apk`

### 4. Build Release APK

```bash
flutter build apk --release
```

The release APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Model Conversion (For Reference)

If you need to convert the model again:

1. Convert Keras model to TensorFlow Lite:
```python
import tensorflow as tf
from tensorflow import keras

model = keras.models.load_model('maize_disease_cnn_model.keras')
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open('maize_disease_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

2. Model specifications:
   - Input size: 227x227 pixels
   - Input format: RGB (3 channels)
   - Normalization: pixel values / 255.0
   - Output: 7 class probabilities

## Dependencies

The app uses the following Flutter packages:

- **tflite_flutter**: ^0.11.0 - TensorFlow Lite inference
- **image_picker**: ^1.1.2 - Camera and gallery access
- **image**: ^4.5.3 - Image processing
- **path_provider**: ^2.1.5 - File system access
- **permission_handler**: ^11.4.0 - Runtime permissions

## Android Configuration

- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Camera permission is required for capture functionality

## Build Notes

- The model is bundled in the assets folder
- Preprocessing matches the training configuration:
  - Resize to 227x227
  - Normalize pixel values to [0, 1] range
- Grad-CAM visualization uses a simplified attention-based approach suitable for mobile

## Troubleshooting

1. **Model loading fails**: Ensure the .tflite file is in `assets/model/` and properly listed in pubspec.yaml

2. **Camera permission denied**: Grant camera permission in app settings

3. **Out of memory**: The image is automatically resized before processing to reduce memory usage

4. **Build errors**: Run `flutter clean` and then `flutter pub get`

## License

This project is provided for educational and research purposes.

## Acknowledgments

- Trained on maize leaf disease dataset with 7 classes
- Model architecture: 15-layer CNN with BatchNorm and Dropout
- Conversion to TensorFlow Lite for mobile deployment# corn_leaf_disease_detection



check my kaggle atuls1124 for dataset
