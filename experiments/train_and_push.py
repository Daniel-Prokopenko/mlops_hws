import os
import shutil
import joblib
import mlflow
import mlflow.sklearn
import numpy as np
from sklearn.datasets import load_iris
from sklearn.linear_model import SGDClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, log_loss
import requests

print("🚀 Запуск ML експериментів з логуванням в MLflow та PushGateway...")

# Налаштування MLflow та PushGateway
mlflow.set_tracking_uri("file:./mlruns")  # Локальний MLflow
PUSHGATEWAY_URL = os.environ.get("PUSHGATEWAY_URL", "http://localhost:9092")
EXPERIMENT_NAME = "Iris_Classifier_1"
BEST_MODEL_DIR = "best_model"

# Параметри для Grid Search
learning_rates = [0.01, 0.05, 0.1]
epochs_list = [50, 100, 200]

print(f"📊 Експеримент: {EXPERIMENT_NAME}")
print(f"🔗 PushGateway: {PUSHGATEWAY_URL}")

# Завантаження датасету
X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

mlflow.set_experiment(EXPERIMENT_NAME)
best_acc = -1
best_run_id = None
best_model_path = None

print(f"\n🧪 Запуск {len(learning_rates)} x {len(epochs_list)} = {len(learning_rates) * len(epochs_list)} експериментів...")

for i, lr in enumerate(learning_rates):
    for j, epochs in enumerate(epochs_list):
        experiment_num = i * len(epochs_list) + j + 1
        print(f"\n📈 Експеримент {experiment_num}/{len(learning_rates) * len(epochs_list)}: lr={lr}, epochs={epochs}")
        
        with mlflow.start_run() as run:
            run_id = run.info.run_id
            
            # Тренування моделі
            clf = SGDClassifier(
                loss="log_loss",
                learning_rate="constant",
                eta0=lr,
                max_iter=epochs,
                random_state=42,
            )
            clf.fit(X_train, y_train)
            
            # Оцінка моделі
            y_pred = clf.predict(X_test)
            y_pred_proba = clf.predict_proba(X_test)
            
            accuracy = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_pred_proba)
            
            print(f"   🎯 Accuracy: {accuracy:.4f}")
            print(f"   📉 Loss: {loss:.4f}")
            
            # Логування в MLflow
            mlflow.log_param("learning_rate", lr)
            mlflow.log_param("epochs", epochs)
            mlflow.log_metric("accuracy", accuracy)
            mlflow.log_metric("loss", loss)
            mlflow.sklearn.log_model(clf, "model")
            
            # Пуш метрик в PushGateway
            try:
                # Правильний формат для PushGateway
                metrics_data = f"""# HELP mlflow_accuracy Accuracy of MLflow experiment
# TYPE mlflow_accuracy gauge
mlflow_accuracy{{run_id="{run_id}",learning_rate="{lr}",epochs="{epochs}"}} {accuracy}

# HELP mlflow_loss Loss of MLflow experiment  
# TYPE mlflow_loss gauge
mlflow_loss{{run_id="{run_id}",learning_rate="{lr}",epochs="{epochs}"}} {loss}
"""
                
                response = requests.post(
                    f"{PUSHGATEWAY_URL}/metrics/job/mlflow_experiment/instance/{run_id}",
                    data=metrics_data,
                    headers={"Content-Type": "text/plain"}
                )
                if response.status_code == 200:
                    print(f"   📤 Метрики відправлені в PushGateway")
                else:
                    print(f"   ⚠️  Помилка PushGateway: {response.status_code}")
            except Exception as e:
                print(f"   ❌ Не вдалося відправити в PushGateway: {e}")
            
            # Відстеження найкращої моделі
            if accuracy > best_acc:
                best_acc = accuracy
                best_run_id = run_id
                best_model_path = f"runs:/{run_id}/model"
                print(f"   🏆 Нова найкраща модель! Accuracy: {best_acc:.4f}")

print(f"\n🎉 Експерименти завершені!")
print(f"🏆 Найкраща модель:")
print(f"   Run ID: {best_run_id}")
print(f"   Accuracy: {best_acc:.4f}")

# Копіювання найкращої моделі
if best_model_path:
    print(f"\n📦 Копіювання найкращої моделі в {BEST_MODEL_DIR}/...")
    
    if os.path.exists(BEST_MODEL_DIR):
        shutil.rmtree(BEST_MODEL_DIR)
    os.makedirs(BEST_MODEL_DIR)
    
    # Завантаження та збереження моделі
    best_model = mlflow.sklearn.load_model(best_model_path)
    joblib.dump(best_model, os.path.join(BEST_MODEL_DIR, "best_model.pkl"))
    
    # Збереження метаданих
    with open(os.path.join(BEST_MODEL_DIR, "metadata.txt"), "w") as f:
        f.write(f"Best Model Metadata\n")
        f.write(f"==================\n")
        f.write(f"Run ID: {best_run_id}\n")
        f.write(f"Accuracy: {best_acc:.4f}\n")
        f.write(f"Model Path: {best_model_path}\n")
    
    print(f"✅ Найкраща модель збережена в {BEST_MODEL_DIR}/")

print(f"\n📊 Переглянути результати:")
print(f"   MLflow UI: http://localhost:8080")
print(f"   PushGateway: {PUSHGATEWAY_URL}/metrics")
print(f"   Найкраща модель: ./{BEST_MODEL_DIR}/best_model.pkl")
