#!/bin/bash

# Функция для проверки запуска с правами sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Пожалуйста, запустите скрипт с sudo."
        exit 1
    fi
}

# Функция для установки ограничения мощности NVIDIA
set_power_limit() {
    local power_limit=250

    # Включаем режим персистентности
    nvidia-smi -pm ENABLED
    echo "Режим персистентности включен."

    # Используем более надежный способ подсчета GPU
    local gpu_count=$(nvidia-smi --list-gpus | wc -l)
    
    # Проверяем наличие двух GPU
    if [ "$gpu_count" -ne 2 ]; then
        echo "Внимание: обнаружено $gpu_count GPU, вместо ожидаемых 2."
    fi

    # Устанавливаем ограничение мощности для каждой GPU отдельно
    nvidia-smi -i 0 -pl $power_limit
    echo "Ограничение мощности установлено на $power_limit Вт для GPU 0."
    
    # Устанавливаем лимит для второй видеокарты, если она есть
    if [ "$gpu_count" -ge 2 ]; then
        nvidia-smi -i 1 -pl $power_limit
        echo "Ограничение мощности установлено на $power_limit Вт для GPU 1."
    fi
}

# Функция для проверки текущих настроек мощности
check_power_settings() {
    echo "Текущие настройки мощности:"
    nvidia-smi -q -d POWER
}

# Функция для создания systemd сервиса
create_systemd_service() {
    local script_path=$(realpath $0)
    local service_file="/etc/systemd/system/nvidia-power-limit.service"
    
    echo "Создание systemd-сервиса..."
    
    # Создаем файл сервиса
    cat > "$service_file" << EOF
[Unit]
Description=Set NVIDIA GPU power limits
After=multi-user.target
After=nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=$script_path --apply
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    # Перезагружаем конфигурацию systemd
    systemctl daemon-reload
    
    # Включаем и запускаем сервис
    systemctl enable nvidia-power-limit.service
    systemctl start nvidia-power-limit.service
    
    echo "Systemd-сервис успешно создан и запущен."
}

# Основное выполнение
if [ "$1" = "--apply" ]; then
    # Эта часть выполняется при запуске сервиса
    set_power_limit
else
    # Эта часть выполняется при настройке
    check_sudo
    set_power_limit
    create_systemd_service
    check_power_settings
    echo "Настройка завершена. Ограничение мощности будет применяться при каждой загрузке системы."
fi 
