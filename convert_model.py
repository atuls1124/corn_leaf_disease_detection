import tensorflow as tf
import numpy as np
from tensorflow import keras
import os

print("TensorFlow version:", tf.__version__)

MODEL_PATH = 'maize_disease_cnn_model.keras'
OUTPUT_DIR = 'converted_model'

os.makedirs(OUTPUT_DIR, exist_ok=True)

print("Loading Keras model...")
model = keras.models.load_model(MODEL_PATH)
print("Model loaded successfully!")

print("\nModel Summary:")
model.summary()

print("\nConverting to TensorFlow Lite...")

converter = tf.lite.TFLiteConverter.from_keras_model(model)

converter.optimizations = [tf.lite.Optimize.DEFAULT]

converter.target_spec.supported_types = [tf.float32]

tflite_model = converter.convert()

output_path = os.path.join(OUTPUT_DIR, 'maize_disease_model.tflite')
with open(output_path, 'wb') as f:
    f.write(tflite_model)

print(f"\nModel converted successfully!")
print(f"Saved to: {output_path}")
print(f"Model size: {os.path.getsize(output_path) / (1024*1024):.2f} MB")

print("\nClass labels mapping:")
class_names = [
    'Bacterial_Leaf_Streak',
    'Common_Rust', 
    'Gray_Leaf_Spot',
    'Healthy',
    'Maize_Chlorotic_Mottle_Virus',
    'Maize_Streak_Virus',
    'Northern_Leaf_Blight'
]

for idx, name in enumerate(class_names):
    print(f"  {idx}: {name}")

with open(os.path.join(OUTPUT_DIR, 'labels.txt'), 'w') as f:
    for name in class_names:
        f.write(name + '\n')

print("\nPreprocessing info saved!")

print("\n" + "="*50)
print("CONVERSION COMPLETE!")
print("="*50)
print(f"Files created in '{OUTPUT_DIR}':")
print(f"  1. maize_disease_model.tflite - The TFLite model")
print(f"  2. labels.txt - Class labels")
print("\nFlutter app preprocessing:")
print("  - Input size: 227x227")
print("  - Normalization: pixel values / 255.0")
print("  - Format: RGB")