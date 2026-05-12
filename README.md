# Деплой приложения через Docker-образ

В этом упражнении мы потренируемся доставлять приложение без реального сервера и платного облака.

Идея: один участник пары собирает Docker-образ и публикует его в Docker Registry, а второй участник скачивает этот образ на своём ноутбуке и запускает приложение. Второй участник не использует исходный код приложения: для него Docker-образ становится готовым артефактом деплоя.

# 0. Подготовка к занятию

Установи Docker. На Windows можно использовать Docker Desktop, для него также понадобится WSL.

Проверь, что Docker работает:

```bash
docker --version
docker run hello-world
```

Для основного задания понадобится аккаунт в Docker Hub: https://hub.docker.com/

Если Docker Hub недоступен или не получается войти, используй запасной вариант из раздела `7. Передача образа без Docker Registry`.

# 1. Роли в паре

Разделитесь на роли:

- Участник A: собирает и публикует Docker-образ.
- Участник B: скачивает опубликованный образ и запускает приложение на своём ноутбуке.

После прохождения упражнения поменяйтесь ролями.

Важное ограничение: участник B не должен запускать `npm install`, открывать папку `deploy-app` или собирать приложение из исходного кода. Он получает только имя Docker-образа и команду запуска.

# 2. Напиши Dockerfile

Основа сборки образа - `Dockerfile`. В нём описываются шаги подготовки окружения для запуска приложения. Подробнее можно изучить в [документации Dockerfile](https://docs.docker.com/reference/dockerfile/).

Создай в корне репозитория файл `Dockerfile` и вставь в него:

```dockerfile
FROM node:20-alpine

COPY deploy-app /app
WORKDIR /app

RUN npm ci

ENV PORT=3000
EXPOSE 3000

CMD ["npm", "start"]
```

Что здесь происходит:

- `FROM` задаёт базовый образ. Здесь используется Node.js 20 на Alpine Linux.
- `COPY` копирует приложение из папки `deploy-app` внутрь образа.
- `WORKDIR` задаёт рабочую директорию для следующих команд.
- `RUN npm ci` устанавливает зависимости по `package-lock.json`.
- `ENV PORT=3000` задаёт порт приложения по умолчанию.
- `EXPOSE 3000` документирует, какой порт слушает контейнер.
- `CMD` задаёт команду запуска приложения.

# 3. Собери и проверь образ локально

Команды выполняет участник A.

Собери образ:

```bash
docker build -t deploy-app:1.0.0 .
```

Запусти контейнер:

```bash
docker run --rm -p 3000:3000 deploy-app:1.0.0
```

Открой в браузере:

```text
http://localhost:3000
```

Если приложение открылось, останови контейнер через `Ctrl+C`.

# 4. Опубликуй образ в Docker Hub

Команды выполняет участник A.

Войди в Docker Hub:

```bash
docker login
```

Затегируй образ. Вместо `dockerhub_username` подставь свой логин в Docker Hub:

```bash
docker tag deploy-app:1.0.0 dockerhub_username/deploy-app:1.0.0
```

Опубликуй образ:

```bash
docker push dockerhub_username/deploy-app:1.0.0
```

После успешной публикации передай участнику B только имя образа:

```text
dockerhub_username/deploy-app:1.0.0
```

# 5. Скачай и запусти образ на втором ноутбуке

Команды выполняет участник B.

Скачай образ. Вместо `dockerhub_username` используй логин участника A:

```bash
docker pull dockerhub_username/deploy-app:1.0.0
```

Запусти контейнер:

```bash
docker run --rm -p 3000:3000 dockerhub_username/deploy-app:1.0.0
```

Открой в браузере:

```text
http://localhost:3000
```

Если приложение открылось, деплой через Docker-образ выполнен успешно.

# 6. Обнови приложение и выпусти новую версию

Теперь участник A должен изменить приложение и выпустить новую версию образа.

Например, можно изменить текст на главной странице в файле `deploy-app/routes/index.js`.

После изменения собери новую версию:

```bash
docker build -t deploy-app:1.0.1 .
```

Затегируй и опубликуй её:

```bash
docker tag deploy-app:1.0.1 dockerhub_username/deploy-app:1.0.1
docker push dockerhub_username/deploy-app:1.0.1
```

Участник B скачивает и запускает новую версию:

```bash
docker pull dockerhub_username/deploy-app:1.0.1
docker run --rm -p 3000:3000 dockerhub_username/deploy-app:1.0.1
```

Проверьте, что в браузере видна обновлённая версия приложения.

# 7. Передача образа без Docker Registry

Этот вариант нужен, если Docker Hub недоступен или нет аккаунта.

Участник A сохраняет образ в файл:

```bash
docker build -t deploy-app:1.0.0 .
docker save deploy-app:1.0.0 -o deploy-app.tar
```

После этого файл `deploy-app.tar` нужно передать участнику B любым удобным способом.

Участник B загружает образ из файла:

```bash
docker load -i deploy-app.tar
```

Проверяет, что образ появился локально:

```bash
docker images
```

Запускает приложение:

```bash
docker run --rm -p 3000:3000 deploy-app:1.0.0
```

Этот способ хуже похож на реальный деплой, потому что образ передаётся файлом. Но он всё равно показывает главный принцип: приложение можно доставить и запустить без установки зависимостей вручную.

# 8. Дополнительное задание: публикация образа через GitHub Actions

В реальных проектах образ обычно собирается не на ноутбуке разработчика, а в CI/CD.

В этом задании GitHub Actions будет автоматически собирать Docker-образ и публиковать его в GitHub Container Registry.

Создай файл `.github/workflows/publish-image.yml`:

```yaml
name: Publish Docker image

on:
  push:
    branches:
      - main

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Prepare image name
        id: image
        run: echo "name=ghcr.io/${GITHUB_REPOSITORY_OWNER,,}/deploy-app:${GITHUB_SHA}" >> "$GITHUB_OUTPUT"

      - name: Build and push image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.image.outputs.name }}
```

Сделай commit и push в GitHub. После успешного выполнения workflow образ появится в Packages.

Чтобы второй участник смог скачать образ без авторизации, package нужно сделать публичным в настройках GitHub Packages.

После этого участник B сможет выполнить:

```bash
docker pull ghcr.io/github_username/deploy-app:commit_sha
docker run --rm -p 3000:3000 ghcr.io/github_username/deploy-app:commit_sha
```

# 9. Контрольные вопросы

Ответь на вопросы после выполнения задания:

- Чем Docker-образ отличается от контейнера?
- Почему участнику B не нужно устанавливать Node.js и зависимости проекта?
- Зачем образу нужен тег?
- Что изменится, если опубликовать новую версию с тем же тегом `latest`?
- Чем передача через Docker Registry лучше передачи файла `deploy-app.tar`?
- Что в этом упражнении является аналогом деплоя на сервер?

# 10. Что должно получиться

В конце упражнения у пары должно быть:

- `Dockerfile` в корне репозитория;
- локально собранный Docker-образ;
- опубликованный образ в Docker Hub или GHCR;
- приложение, запущенное на втором ноутбуке без исходного кода;
- понимание, что Docker-образ можно использовать как переносимый артефакт деплоя.
