\
    # Домашнє завдання: Bash + Docker для ML inference

    ## Структура
    ```
    .
    ├── inference.py
    ├── export_model.py
    ├── model.pt
    ├── Dockerfile.fat
    ├── Dockerfile.slim
    ├── install_dev_tools.sh
    ├── comparison.txt
    └── README.md
    ```

    ## 1) Підготовка середовища (Linux)
    ```bash
    chmod +x install_dev_tools.sh
    ./install_dev_tools.sh
    ```

    > Якщо скрипт додав тебе в групу `docker`, потрібно вийти/зайти в систему (або перезапустити shell).

    ## 2) Експорт моделі в TorchScript
    ```bash
    python3 export_model.py --output model.pt
    ```

    Скрипт завантажить `mobilenet_v2` з `torchvision` і збереже TorchScript у `model.pt`.

    ## 3) Збірка Docker-образів
    ```bash
    docker build -t ml-fat  -f Dockerfile.fat  .
    docker build -t ml-slim -f Dockerfile.slim .
    ```

    ## 4) Запуск inference (потрібне будь-яке зображення)
    Приклад: `sample.jpg` у поточній папці.

    **Linux/macOS**
    ```bash
    docker run --rm -v "$PWD/sample.jpg:/data/image.jpg:ro" ml-fat
    docker run --rm -v "$PWD/sample.jpg:/data/image.jpg:ro" ml-slim
    ```

    **Windows PowerShell**
    ```powershell
    docker run --rm -v "${PWD}\sample.jpg:/data/image.jpg:ro" ml-fat
    docker run --rm -v "${PWD}\sample.jpg:/data/image.jpg:ro" ml-slim
    ```

    На виході буде топ-3 класи ImageNet з ймовірностями.

    ## 5) Звіт
    Заповни `comparison.txt` своїми числами після збірки та запуску.

    Корисні команди:
    ```bash
    docker image ls | grep -E "ml-fat|ml-slim"
    docker history --no-trunc ml-fat
    docker history --no-trunc ml-slim
    ```
