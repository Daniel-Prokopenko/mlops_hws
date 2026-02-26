import mlflow
import mlflow.sklearn
import numpy as np
from sklearn.datasets import load_iris
from sklearn.linear_model import SGDClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

print("🚀 Запускаємо локальні ML експерименти...")

# Використовуємо локальну папку замість сервера
mlflow.set_tracking_uri("file:./mlruns")

# Завантаження датасету
X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Простий експеримент
mlflow.set_experiment("Simple_Iris_Test")

with mlflow.start_run() as run:
    clf = SGDClassifier(learning_rate="constant", eta0=0.1, max_iter=100, random_state=42)
    clf.fit(X_train, y_train)
    
    # Предикція
    y_pred = clf.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"📊 Accuracy: {accuracy:.3f}")
    
    # Логування в MLflow
    mlflow.log_param("learning_rate", 0.1)
    mlflow.log_param("max_iter", 100)
    mlflow.log_metric("accuracy", accuracy)
    mlflow.sklearn.log_model(clf, "model")
    
    print(f"✅ Експеримент збережено! Run ID: {run.info.run_id}")

print("🎉 Експерименти завершені! Перевірте папку ./mlruns")
