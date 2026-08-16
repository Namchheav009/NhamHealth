Installed model: Google AIY Food Classifier V1

- `food_model.tflite`: official 2,023-dish MobileNet food classifier
- `food_labels.txt`: 2,024 matching English output labels, including background
- Source: https://www.kaggle.com/models/google/aiy/tfLite/vision-classifier-food-v1/1
- License: Apache 2.0

The model expects 224 x 224 RGB float input normalized to [0, 1]. Nutrition
values are intentionally loaded from the NhamHealth API rather than inferred
from the image.
