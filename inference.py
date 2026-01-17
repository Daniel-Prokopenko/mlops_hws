import argparse
from pathlib import Path
from typing import List, Tuple

import torch
from PIL import Image
import torchvision.transforms as T
import torchvision


def build_preprocess() -> T.Compose:
    # Standard ImageNet preprocessing
    return T.Compose(
        [
            T.Resize(256),
            T.CenterCrop(224),
            T.ToTensor(),
            T.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ]
    )


def get_imagenet_categories() -> List[str]:
    # Categories are baked into torchvision weights metadata.
    return torchvision.models.MobileNet_V2_Weights.DEFAULT.meta["categories"]


def predict_topk(
    model: torch.jit.RecursiveScriptModule,
    image_path: Path,
    topk: int = 3,
) -> List[Tuple[int, float]]:
    img = Image.open(image_path).convert("RGB")
    x = build_preprocess()(img).unsqueeze(0)  # [1,3,224,224]

    with torch.no_grad():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)[0]
        values, indices = torch.topk(probs, k=topk)

    return list(zip(indices.tolist(), values.tolist()))


def main() -> None:
    parser = argparse.ArgumentParser(description="Simple TorchScript inference (top-3 classes).")
    parser.add_argument("image", help="Path to input image.")
    parser.add_argument("--model-path", default="model.pt", help="Path to TorchScript model.")
    parser.add_argument("--topk", type=int, default=3, help="How many top predictions to show.")
    args = parser.parse_args()

    image_path = Path(args.image)
    model_path = Path(args.model_path)

    if not model_path.exists():
        raise SystemExit(f"Model not found: {model_path.resolve()}")
    if not image_path.exists():
        raise SystemExit(f"Image not found: {image_path.resolve()}")

    model = torch.jit.load(str(model_path), map_location="cpu")
    model.eval()

    categories = get_imagenet_categories()
    preds = predict_topk(model, image_path, topk=args.topk)

    for rank, (idx, prob) in enumerate(preds, start=1):
        label = categories[idx] if 0 <= idx < len(categories) else f"class_{idx}"
        print(f"{rank}. {label} (idx={idx}) — {prob*100:.2f}%")


if __name__ == "__main__":
    main()
