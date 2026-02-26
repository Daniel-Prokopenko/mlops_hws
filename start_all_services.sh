#!/bin/bash

echo "🚀 Запуск всіх MLOps сервісів одночасно..."

# Перевіряємо, чи всі поди готові
echo "📊 Перевірка статусу подів..."
kubectl get pods -n mlflow
kubectl get pods -n monitoring

# Завершуємо існуючі port-forward процеси
echo "🔄 Завершення існуючих port-forward процесів..."
pkill -f "kubectl port-forward" || true

# Запускаємо port-forward для всіх сервісів в фоновому режимі
echo "🌐 Налаштування port-forward для всіх сервісів..."

# MLflow namespace
echo "📈 MLflow сервіси..."
kubectl port-forward svc/minio -n mlflow 9002:9000 9003:9001 > /tmp/minio-pf.log 2>&1 &
echo "   ✅ MinIO API: http://localhost:9002"
echo "   ✅ MinIO Console: http://localhost:9003 (minio/minio123)"

kubectl port-forward svc/pushgateway-prometheus-pushgateway -n mlflow 9092:9091 > /tmp/pushgateway-pf.log 2>&1 &
echo "   ✅ PushGateway: http://localhost:9092/metrics"

# Monitoring namespace  
echo "📊 Monitoring сервіси..."
kubectl port-forward svc/grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &
echo "   ✅ Grafana: http://localhost:3000 (admin/admin123)"

kubectl port-forward svc/prometheus-server -n monitoring 9090:80 > /tmp/prometheus-pf.log 2>&1 &
echo "   ✅ Prometheus: http://localhost:9090"

# Чекаємо трохи, щоб port-forward встигли запуститися
sleep 3

echo "🎯 Активація Python середовища та запуск MLflow UI..."
source mlops-env/bin/activate
mlflow ui --backend-store-uri file:./mlruns --port 8080 > /tmp/mlflow-ui.log 2>&1 &
echo "   ✅ MLflow UI: http://localhost:8080"

echo ""
echo "🎉 Всі сервіси запущені!"
echo ""
echo "📋 Доступні сервіси:"
echo "   🔹 MLflow UI:      http://localhost:8080"
echo "   🔹 Grafana:        http://localhost:3000 (admin/admin123)"
echo "   🔹 Prometheus:     http://localhost:9090"  
echo "   🔹 MinIO Console:  http://localhost:9003 (minio/minio123)"
echo "   🔹 MinIO API:      http://localhost:9002"
echo "   🔹 PushGateway:    http://localhost:9092/metrics"
echo ""
echo "🧪 Для запуску ML експериментів:"
echo "   source mlops-env/bin/activate && python experiments/train_and_push.py"
echo ""
echo "🛑 Для зупинки всіх сервісів:"
echo "   pkill -f 'kubectl port-forward' && pkill -f 'mlflow ui'"
