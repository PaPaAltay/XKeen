#!/bin/sh

# 1. Установка зависимостей
echo "Обновление списка пакетов..."
if ! opkg update; then
    echo "Ошибка: не удалось обновить список пакетов."
    exit 1
fi

# Обновление пакетов является опциональным, можно пропустить
# echo "Обновление установленных пакетов..."
# opkg upgrade # Не проверяем статус, так как не критично

echo "Установка curl и tar..."
if ! opkg install curl tar; then
    echo "Ошибка: не удалось установить curl или tar."
    exit 1
fi

# 2. Проверка директории /opt/sbin
if [ ! -d "/opt/sbin" ]; then
  echo "Ошибка: директория /opt/sbin не найдена. Убедитесь, что entware установлена и смонтирована."
  exit 1
fi

# 3. Определение URL для загрузки
# Используем прямую ссылку на последний релиз
url="https://github.com/jameszeroX/XKeen/releases/latest/download/xkeen.tar.gz"

# 4. Функция для загрузки файла с проверкой
download_file() {
    local target_url="$1"
    local expected_filename="xkeen.tar.gz" # Указываем ожидаемое имя файла
    echo "Попытка загрузки: $target_url"
    if curl -OL --connect-timeout 10 -m 60 "$target_url"; then
        # Проверяем, что файл скачался, существует и не пустой
        if [ -f "$expected_filename" ] && [ -s "$expected_filename" ]; then
            echo "Загрузка $expected_filename успешна."
            return 0
        else
            echo "Ошибка: файл $expected_filename не найден или пуст после загрузки."
            # Удаляем пустой файл, если он есть
            rm -f "$expected_filename" 2>/dev/null
            return 1
        fi
    else
        echo "Ошибка загрузки по URL: $target_url"
        return 1
    fi
}

# 5. Попытка загрузки с основного URL
if download_file "$url"; then
    download_success=true
else
    echo "Не удалось загрузить с основного URL, пробуем альтернативные источники..."

    # Используем рекомендованные прокси из описания репозитория и информации о gh-proxy.com
    # Важно: для прокси формат должен быть PROXY_URL/ORIGINAL_URL
    alt_url_1="https://edgeone.gh-proxy.com/$url"
    if download_file "$alt_url_1"; then
        download_success=true
    else
        alt_url_2="https://v6.gh-proxy.org/$url"
        if download_file "$alt_url_2"; then
            download_success=true
        else
            # ghfast.top может быть недоступен, как показал веб-скрейпинг
            # alt_url_3="https://ghfast.top/$url"
            # if download_file "$alt_url_3"; then
            #     download_success=true
            # else
                echo "Все попытки загрузки не удалась."
                exit 1
            # fi
        fi
    fi
fi

# 6. Распаковка и запуск установки XKeen
if [ "$download_success" = true ]; then
    # Используем tar с флагом -f для указания имени файла явно (хорошая практика)
    if tar -xvzf "xkeen.tar.gz" -C /opt/sbin > /dev/null 2>&1; then
        # Успешно распаковано
        rm "xkeen.tar.gz" # Удаляем архив после распаковки
        echo "Архив XKeen успешно распакован в /opt/sbin."

        # Проверяем, существует ли исполняемый файл xkeen после распаковки
        if [ -x "/opt/sbin/xkeen" ]; then
            echo "Запуск установки XKeen..."
            # Запускаем скрипт XKeen с параметром установки
            /opt/sbin/xkeen -i
        else
            echo "Ошибка: исполняемый файл /opt/sbin/xkeen не найден или не является исполняемым после распаковки."
            exit 1
        fi
    else
        # Ошибка распаковки tar
        echo "Ошибка: не удалось распаковать архив xkeen.tar.gz с помощью tar."
        # Удаляем поврежденный архив
        rm -f "xkeen.tar.gz" 2>/dev/null
        exit 1
    fi
else
    # Эта ветка в теории не должна сработать, если логика выше корректна,
    # но оставим на всякий случай
    echo "Критическая ошибка: файл не был успешно загружен."
    exit 1
fi

echo "Скрипт установки завершен."
