#!/bin/bash

echo "🛑 Зупинка всіх MLOps сервісів..."

# Завершуємо всі port-forward процеси
echo "🔄 Завершення port-forward процесів..."
pkill -f "kubectl port-forward"

# Завершуємо MLflow UI
echo "🔄 Завершення MLflow UI..."
pkill -f "mlflow ui"

# Перевіряємо, що процеси завершені
echo "📊 Перевірка активних процесів..."
ps aux | grep -E "(port-forward|mlflow)" | grep -v grep || echo "✅ Всі процеси завершені"

echo "✅ Всі MLOps сервіси зупинені!"
