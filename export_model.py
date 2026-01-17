import argparse
from pathlib import Path

import torch
import torchvision


def export_mobilenet_v2(output_path: Path) -> None:
    # Download weights on first run
    weights = torchvision.models.MobileNet_V2_Weights.DEFAULT
    model = torchvision.models.mobilenet_v2(weights=weights)
    model.eval()

    # TorchScript export (script is usually more robust than trace)
    scripted = torch.jit.script(model)
    scripted.save(str(output_path))


def main() -> None:
    parser = argparse.ArgumentParser(description="Export torchvision model to TorchScript (.pt).")
    parser.add_argument("--output", default="model.pt", help="Output path for TorchScript model.")
    args = parser.parse_args()

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    export_mobilenet_v2(out)
    print(f"Saved TorchScript model to: {out.resolve()}")


if __name__ == "__main__":
    main()
