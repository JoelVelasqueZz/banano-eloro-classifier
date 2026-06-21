import numpy as np
from PIL import Image
from ai_edge_litert.interpreter import Interpreter

MODEL_PATH = r"..\banano_eloro_app\assets\mobilenet_v2_banano.tflite"
IMAGE_PATH = r"prueba\sigatoka.jpeg"

interpreter = Interpreter(model_path=MODEL_PATH)
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("INPUT DETAILS:")
for d in input_details:
    print(" ", d)
print("OUTPUT DETAILS:")
for d in output_details:
    print(" ", d)

interpreter.allocate_tensors()

img = Image.open(IMAGE_PATH).convert("RGB").resize((224, 224))
arr = np.asarray(img).astype(np.float32) / 255.0
mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
arr = (arr - mean) / std
arr = np.transpose(arr, (2, 0, 1))  # HWC -> CHW
arr = np.expand_dims(arr, axis=0).astype(np.float32)  # -> NCHW

print("Input array shape:", arr.shape, arr.dtype)

interpreter.set_tensor(input_details[0]["index"], arr)
interpreter.invoke()

output = interpreter.get_tensor(output_details[0]["index"])
print("OUTPUT:", output)
classes = ["Sigatoka", "Cordana", "Pestalotiopsis", "Healthy", "Moko", "Panama_Disease", "Insect_Pest"]
best = int(np.argmax(output[0]))
print(f"Predicted: {classes[best]} ({output[0][best]*100:.1f}%)")
